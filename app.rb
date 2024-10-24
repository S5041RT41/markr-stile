#!/usr/bin/ruby
# frozen_string_literal: true

# app.rb

require 'sinatra'
require 'nokogiri'
require 'redis'

# Constants for error codes
RESOURCE_NOT_FOUND = { code: 'RESOURCE_NOT_FOUND', message: 'The requested resource was not found.',
                       suggestion: 'Please check user documentation for the correct path.' }.freeze
BAD_REQUEST = { code: 'BAD_REQUEST', message: 'Current request does not satisfy request parameters.',
                suggestion: 'Please check user documentation.' }.freeze
SERVER_ERROR = { code: 'SERVER_ERROR', message: 'Current request cannot be processed.',
                 suggestion: 'Please check user documentation.' }.freeze

# Markr processor
class Markr < Sinatra::Base
  redis_uri = URI.parse(ENV['REDIS_URL'] || 'redis://markr-redis:6379' )
  redis = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)

  helpers do
    def json_response(data)
      content_type :json
      data.to_json
    end

    def handle_error(status, error_data)
      halt status, error_data.to_json
    end
  end

  not_found do
    handle_error(404, RESOURCE_NOT_FOUND)
  end

  error 400 do
    error_message = body[0] || BAD_REQUEST[:message]
    handle_error(400, BAD_REQUEST.merge(message: error_message))
  end

  error 405..511 do
    handle_error(500, SERVER_ERROR)
  end

  def process_students(raw_individual_test_results)
    students = {}
    raw_individual_test_results.each do |node|
      student_number = node.at('student-number').text
      obtained_marks = node.at('summary-marks')['obtained']
      available_marks = node.at('summary-marks')['available']

      students[student_number] ||= {
        first_name: node.at('first-name').text,
        student_number: student_number,
        last_name: node.at('last-name').text,
        available_marks: available_marks,
        obtained_marks: obtained_marks
      }.to_json

      update_student_if_needed(students[student_number], obtained_marks, available_marks)
    end
    students
  end

  def update_student_if_needed(student_json, obtained_marks, available_marks)
    j_student = JSON.parse(student_json)
    if j_student['obtained_marks'].to_f < obtained_marks.to_f
      j_student['obtained_marks'] = obtained_marks
      j_student['available_marks'] = available_marks
    end
    j_student.to_json
  end

  configure do
    set :json_encoder, :to_json
    set :show_exceptions, :after_handler
    set default_content_type: nil
    enable :sessions, :logging
  end

  before do
    headers['Access-Control-Allow-Methods'] = 'GET, POST'
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  end

  options '*' do
    response.headers['Allow'] = 'GET,POST'
    response.headers['Access-Control-Allow-Headers'] =
      'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  end

  get '/results/:testid/aggregate' do |testid|
    content_type :json

    # Get all data for the specified test
    students = redis.hvals(testid)
    student_count = students.size.to_f
    mean = 0
    p25 = 0
    p50 = 0
    p75 = 0

    # If no data has been found, return default zero values
    if student_count.zero?
      {
        mean: mean,
        count: 0,
        p25: p25,
        p50: p50,
        p75: p75
      }.to_json
    else

      # If students have been found, sort them by the obtained marks to calculate percentile
      students.sort_by { |s| JSON.parse(s)['obtained_marks'].to_f }.each_with_index do |student, index|
        j_student = JSON.parse(student)
        j_obtained_marks_float = j_student['obtained_marks'].to_f

        # Sum all obtained marks for future mean calculations
        mean += j_obtained_marks_float
        if (0.25 * student_count).ceil == index + 1
          p25 = j_obtained_marks_float
        elsif (0.5 * student_count).ceil == index + 1
          p50 = j_obtained_marks_float
        elsif (0.75 * student_count).ceil == index + 1
          p75 = j_obtained_marks_float
        end
      end

      {
        mean: (mean / student_count.to_f).round(2),
        count: student_count.to_i,
        p25: p25,
        p50: p50,
        p75: p75
      }.to_json
    end
  end

  post '/import' do
    content_type 'text/xml+markr'

    # Check whether data has been sent
    handle_error(400, BAD_REQUEST) if request.content_length.nil?

    # Open xml schema
    payload_schema = Nokogiri::XML::Schema(File.read(File.expand_path('./config/xml-payload-schema.xsd',
                                                                      File.dirname(__FILE__))))

    # Read the provided payload
    @data = Nokogiri::XML(request.body.read)

    # Validate that payload matches the schema
    validated_data = payload_schema.validate(@data)

    # Return errors in the file
    handle_error(400, { message: "Incorrect file detected. #{validated_data.join(', ')}" }) if validated_data.any?

    # Get the date of the scan
    scan_date = Date.parse(@data.at('mcq-test-result')['scanned-on'])

    # Get test id
    test_id = @data.at('test-id').text

    # Store file in redis
    redis.set("#{test_id}-#{scan_date}-raw", @data.to_xml)

    # Get essential user data and convert to Hash
    students = process_students(@data.css('mcq-test-result'))

    # Store students data
    redis.hmset(test_id, *students)

    { code: 'SUCCESS', message: 'Request has been submitted.' }.to_json
  end
end
