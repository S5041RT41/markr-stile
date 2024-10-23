require 'bundler'
require 'rack/protection'

Bundler.require

require './app/app.rb'

use Rack::Protection

run Markr