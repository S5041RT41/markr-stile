# frozen_string_literal: true

# spec/spec_helper.rb
require 'rack/test'
require 'rspec'
require 'json'
require_relative '../app' # Adjust this if your app file has a different name or path

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:each) do
    # Mock Redis
    @redis = instance_double('Redis')
    allow(Redis).to receive(:new).and_return(@redis)
  end
end
