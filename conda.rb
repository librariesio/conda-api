# coding: utf-8
# frozen_string_literal: true

require "httparty"
require "json"
require "singleton"

class Conda
  include Singleton

  attr_reader :main

  def initialize
    @main = Conda::Channel.new("pkgs/main", "repo.anaconda.com")
  end

  class Channel
    ARCHES = %w[linux-64 osx-64 win-64 noarch].freeze

    attr_reader :timestamp, :packages

    def initialize(channel, domain)
      @channel = channel
      @domain = domain
      @timestamp = Time.now
      @mutex = Mutex.new
      reload
    end

    def reload
      @mutex.synchronize { @packages = retrieve_packages }
      @timestamp = Time.now
    end

    private

    def retrieve_packages
      packages = {}
      channeldata = HTTParty.get("https://#{@domain}/#{@channel}/channeldata.json")["packages"]
      ARCHES.each do |arch|
        blob = HTTParty.get("https://#{@domain}/#{@channel}/#{arch}/repodata.json")["packages"]
        blob.each_key do |key|
          package_name = package["name"]

          unless packages.has_key?(package_name)
            package_data = channeldata[package_name]
            packages[package_name] = base_package(package_data, package_name)
          end

          packages[package_name][:versions] << release_version(blob[key])
        end
      end
      remove_duplicate_versions(packages)
    end

    def base_package(package_data, package_name)
      {
        versions: [],
        repository_url: package_data["dev_url"],
        homepage: package_data["home"],
        licenses: package_data["license"],
        description: package_data["description"],
        name: package_name
      }
    end

    def release_version(package_version)
      {
        number: package["version"],
        original_license: package["license"],
        published_at: package["timestamp"].nil? ? nil : Time.at(package["timestamp"] / 1000),
        dependencies: package["depends"]
      }
    end

    def remove_duplicate_versions(packages)
      packages.values.each do |value|
        value[:versions] = value[:versions].uniq { |vers| vers[:number] }
      end
      packages
    end
  end
end
