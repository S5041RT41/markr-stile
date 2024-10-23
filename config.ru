require 'bundler'
require 'rack/protection'

Bundler.require

require './src/app.rb'

use Rack::Protection

run Markr