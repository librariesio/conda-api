# frozen_string_literal: true

require "bundler"
Bundler.require

require "./conda"

loop do
  Conda.instance.update_packages
  sleep 900
end
