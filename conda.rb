# frozen_string_literal: true

require "httparty"
require "json"
require "singleton"

class Conda
  include Singleton

  attr_reader :main

  def initialize
    @main = Conda::Channel.new("pkgs/main", "repo.anaconda.com", "channeldata.json")
  end

  class Channel
    ARCHES = %w[linux-64 osx-64 win-64 noarch].freeze

    attr_reader :timestamp, :packages

    def initialize(channel, domain, path)
      @channel = channel
      @domain = domain
      @path = path
      @timestamp = Time.now
      @mutex = Mutex.new
      reload
    end

    def package_names
      @packages.keys
    end

    def reload
      @mutex.synchronize { @packages = retrieve_packages }
      @timestamp = Time.now
    end

    private

    def retrieve_packages
      packs = Hash.new { |hash, key| hash[key] = [] }
      ARCHES.each do |arch|
        blob = HTTParty.get("https://#{@domain}/#{@channel}/#{arch}/repodata.json")["packages"]
        blob.each_key do |key|
          package = blob[key]
          packs["#{@channel}/#{package["name"]}"] << { version: package["version"], license: package["license"], timestamp: package["timestamp"], arch: arch }
        end
      end
      packs
    end
  end
end
