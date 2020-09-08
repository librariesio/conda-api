# frozen_string_literal: true

require "bundler"
Bundler.require

require "./conda"

Conda.instance.update_packages
