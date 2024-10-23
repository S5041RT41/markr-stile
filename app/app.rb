#!/usr/bin/ruby
# app.rb

require 'sinatra'
require 'nokogiri'
require 'redis'

ENV['REDIS_URL'] ||= 'redis://localhost:6379'

class Markr < Sinatra::Base

  configure do
    set :json_encoder, :to_json
    set :show_exceptions, :after_handler
    set :default_content_type => nil
    enable :sessions, :logging
  end

  not_found do
    error_data = {
      :code => "RESOURCE_NOT_FOUND",
      :message => "The requested resource was not found.",
      :suggestion => "Please check user documentation for the correct path."
    }
    error_data.to_json
  end

  error 400 do
    error_data = {
      :code => "BAD_REQUEST",
      :message => "Current request does not satisfy request parameters.",
      :suggestion => "Please check user documentation."
    }
    error_data.to_json
  end

  error 405..511 do
    error_data = {
      :code => "SERVER_ERROR",
      :message => "Current request cannot be processed.",
      :suggestion => "Please check user documentation."
    }
    error_data.to_json
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

  # Redis configuration
  RedisURI = URI.parse(ENV["REDIS_URL"])
  REDIS = Redis.new(host: RedisURI.host, port: RedisURI.port, password: RedisURI.password)

  get "/results/:testid/aggregate" do |testid|
    content_type :json
    data = {"Hi" => "Hello", "Bye" => "Goodbye"}
    data.to_json
  end

  post '/import' do
    content_type "text/xml+markr"

    logger.debug request.content_length

    # Check whether data has been sent
    if request.content_length.nil?
      halt 400
    else
      @data = Nokogiri::XML(request.body.read)
      student_numbers = @data.xpath("//student-number")
      test_id = @data.xpath("//test-id")

      logger.info test_id
      logger.info student_numbers

      {
        :code => "SUCCESS",
        :message => "Request has been submitted."
      }.to_json
    end

  end
end
