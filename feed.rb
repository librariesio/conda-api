require 'bundler'
Bundler.require

require './conda'

loop do
  Conda.instance.update_packages
  sleep 300
end
