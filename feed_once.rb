require 'bundler'
Bundler.require

require './conda'

Conda.instance.update_packages
