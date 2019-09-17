require 'bundler'
Bundler.require

require File.expand_path '../app.rb', __FILE__

require "sinatra/base"
require_relative "conda"
require_relative "app"
require "builder"

run CondaAPI
