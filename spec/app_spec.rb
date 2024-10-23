require "./src/app"
require 'rack/test'

ENV['RACK_ENV'] = 'test'

describe Markr do
  include Rack::Test::Methods

  expected_not_found = { 
    :code  => "RESOURCE_NOT_FOUND",
    :message     => "The requested resource was not found.",
    :suggestion    => "Please check user documentation for the correct path."
  }.to_json

  expected_server_error = { 
    :code  => "SERVER_ERROR",
    :message     => "Current request cannot be processed.",
    :suggestion    => "Please check user documentation."
  }.to_json

  expected_bad_request = { 
    :code  => "BAD_REQUEST",
    :message     => "Current request does not satisfy request parameters.",
    :suggestion    => "Please check user documentation."
  }.to_json

  expected_successful_request = { 
    :code  => "SUCCESS",
    :message     => "Request has been submitted"
  }.to_json
  
  context "get to /" do
    let(:app) { Markr.new }

    it "returns 404" do
      get "/"
      expect(last_response.status).to eq 404
    end

    it "returns not found error" do
      get "/"
      expect(last_response.body).to eq expected_not_found
    end
  end

  context "get /results" do
    let(:app) { Markr.new }

    it "returns 404 without parameters" do
      get "/results"
      expect(last_response.status).to eq 404
    end

    it "returns not found error without parameters" do
      get "/results"
      expect(last_response.body).to eq expected_not_found
    end
  end
  
  context "get /results/:test-id/aggregate" do
    let(:app) { Markr.new }

    it "returns 200 with test id" do
      get "/results/1234/aggregate"
      expect(last_response.status).to eq 200
    end

    it "returns json results" do
      get "/results/122/aggregate"
      expect(last_response.body).to eq ""
    end

  end

  context "post /import" do
    let(:app) { Markr.new }

    xml_body_pass = '<?xml version="1.0" encoding="UTF-8" ?><mcq-test-results><mcq-test-result scanned-on="2017-01-01T00:00:00Z"><first-name>Jimmmy</first-name><last-name>Student</last-name><student-number>99999999</student-number><test-id>78763</test-id><summary-marks available="10" obtained="2" /><answer question="1" marks-available="1" marks-awarded="1">A</answer><answer question="2" marks-available="1" marks-awarded="0">B</answer><answer question="4 marks-available="1" marks-awarded="1">AC</answer></mcq-test-result>...more mcq-test-result elements follow...</mcq-test-results>'

    post_headers_pass = { "CONTENT_TYPE" => "text/xml+markr" }

    it "returns 400 without body" do
      post "/import"
      expect(last_response.status).to eq 400
    end

    it "returns bad request without body" do
      post "/import"
      expect(last_response.body).to eq expected_bad_request
    end

    it "returns 200 with correct body" do
      post '/import', params: { body: xml_body_pass }, :headers => post_headers_pass
      expect(last_response.status).to eq 200
    end

    it "returns successful request with correct body" do
      post '/import', params: { body: xml_body_pass }, :headers => post_headers_pass
      expect(last_response.body).to eq expected_successful_request
    end

  end

end
