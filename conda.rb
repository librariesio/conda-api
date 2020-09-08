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

    attr_reader :timestamp

    def initialize(channel, domain)
      @channel = channel
      @domain = domain
      @timestamp = Time.now
      @lock = Concurrent::ReadWriteLock.new
      reload
    end

    def reload
      new_packages = retrieve_packages
      @lock.with_write_lock { @packages = new_packages }
      @timestamp = Time.now
    end

    def packages
      @lock.with_read_lock { @packages }
    end

    private

    def retrieve_packages
      packages = {}
      channeldata = HTTParty.get("https://#{@domain}/#{@channel}/channeldata.json")["packages"]
      ARCHES.each do |arch|
        blob = HTTParty.get("https://#{@domain}/#{@channel}/#{arch}/repodata.json")["packages"]
        blob.each_key do |key|
          version = blob[key]
          package_name = version["name"]

          unless packages.key?(package_name)
            package_data = channeldata[package_name]
            packages[package_name] = base_package(package_data, package_name)
          end

          packages[package_name][:versions] << release_version(version)
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
        name: package_name,
      }
    end

    def release_version(package_version)
      {
        number: package_version["version"],
        original_license: package_version["license"],
        published_at: package_version["timestamp"].nil? ? nil : Time.at(package_version["timestamp"] / 1000),
        dependencies: package_version["depends"],
      }
    end

    def remove_duplicate_versions(packages)
      packages.each_value do |value|
        value[:versions] = value[:versions].uniq { |vers| vers[:number] }
      end
      packages
    end
  end
end
