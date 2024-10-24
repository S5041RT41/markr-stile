# frozen_string_literal: true

# spec/app_spec.rb
require 'spec_helper'

RSpec.describe 'Markr API', type: :request do
  let(:app) { Markr.new }
  let(:redis) { instance_double('Redis') }

  before do
    allow(Redis).to receive(:new).and_return(redis)
  end

  describe 'GET /results/:testid/aggregate' do
    before do
      allow(redis).to receive(:hvals).with('5678').and_return(
        [
          { 'obtained_marks' => 75, 'available_marks' => 100 }.to_json,
          { 'obtained_marks' => 85, 'available_marks' => 100 }.to_json
        ]
      )
      allow(redis).to receive(:hvals).with('invalid_test').and_return([])
    end

    context 'when there are students found' do
      it 'returns aggregated results for a valid test ID' do
        get '/results/5678/aggregate'

        expect(last_response).to be_ok

        json_response = JSON.parse(last_response.body)

        expect(json_response).to include(
          'count' => 2,
          'mean' => 80.0,
          'p25' => 75.0,
          'p50' => 80.0,
          'p75' => 85.0
        )
      end
    end

    context 'when no students found' do
      it 'returns default values for an invalid test ID' do
        get '/results/invalid_test/aggregate'
        expect(last_response).to be_ok

        json_response = JSON.parse(last_response.body)

        expect(json_response).to include(
          'count' => 0,
          'mean' => 0.0,
          'p25' => 0,
          'p50' => 0,
          'p75' => 0
        )
      end
    end
  end

  describe 'POST /import' do
    let(:valid_xml) do
      <<~XML
        <mcq-test-results>
          <mcq-test-result scanned-on="2023-10-01">
            <test-id>5678</test-id>
            <student-number>student1</student-number>
            <first-name>John</first-name>
            <last-name>Doe</last-name>
            <summary-marks obtained="80" available="100"/>
          </mcq-test-result>
        </mcq-test-results>
      XML
    end

    context 'with valid XML' do
      it 'imports and responds with success' do
        allow(redis).to receive(:set).with('5678-2023-10-01-raw', anything)

        post '/import', valid_xml, { 'CONTENT_TYPE' => 'text/xml+markr' }
        expect(last_response).to be_ok

        json_response = JSON.parse(last_response.body)

        expect(json_response).to include(
          'code' => 'SUCCESS',
          'message' => 'Request has been submitted.'
        )
      end
    end

    context 'with invalid XML' do
      it 'returns 400 for invalid XML' do
        post '/import', '<invalid_xml>', { 'CONTENT_TYPE' => 'text/xml+markr' }
        expect(last_response.status).to eq(400)

        json_response = JSON.parse(last_response.body)
        expect(json_response).to include(
          'code' => 'BAD_REQUEST'
        )
      end
    end

    context 'with no data sent' do
      it 'returns 400 if no data is sent' do
        post '/import', '', { 'CONTENT_TYPE' => 'text/xml+markr' }
        expect(last_response.status).to eq(400)

        json_response = JSON.parse(last_response.body)
        expect(json_response).to include(
          'code' => 'BAD_REQUEST'
        )
      end
    end
  end
end
