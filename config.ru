# frozen_string_literal: true

require 'bundler'
require 'rack/protection'

Bundler.require

require './app/app'

use Rack::Protection

run Markr
