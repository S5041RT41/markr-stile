# frozen_string_literal: true

require 'bundler/setup' # Ensures the gems specified in Gemfile are loaded
require 'rack/protection'

Bundler.require(:default) # Load gems in the default group

require_relative './app' # Relative require for better portability

# Middleware to enhance security
use Rack::Protection

run Markr
