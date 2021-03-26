# frozen_string_literal: true

require "httparty"
require "json"

class Channel
  ARCHES = %w[linux-32 linux-64 linux-aarch64 linux-armv6l linux-armv7l linux-ppc64le osx-64 win-64 win-32 noarch zos-z].freeze

  attr_reader :timestamp

  def initialize(channel, domain)
    @channel_name = channel
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

  def only_one_version_packages
    @lock.with_read_lock { remove_duplicate_versions(@packages) }
  end

  private

  def retrieve_packages
    packages = {}
    channeldata = HTTParty.get("https://#{@domain}/#{@channel_name}/channeldata.json")["packages"]
    ARCHES.each do |arch|
      blob = HTTParty.get("https://#{@domain}/#{@channel_name}/#{arch}/repodata.json")["packages"]
      blob.each_key do |key|
        version = blob[key]
        package_name = version["name"]

        unless packages.key?(package_name)
          package_data = channeldata[package_name]
          packages[package_name] = base_package(package_data, package_name)
        end

        packages[package_name][:versions] << release_version(key, version)
      end
    end
    packages
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

  def release_version(artifact, package_version)
    {
      artifact: artifact,
      download_url: "https://#{@domain}/#{@channel_name}/#{package_version['subdir']}/#{artifact}",
      number: package_version["version"],
      original_license: package_version["license"],
      published_at: package_version["timestamp"].nil? ? nil : Time.at(package_version["timestamp"] / 1000),
      dependencies: package_version["depends"],
      arch: package_version["subdir"],
      channel: @channel_name,
    }
  end

  def remove_duplicate_versions(packages)
    packages.each_value do |value|
      value[:versions] = value[:versions].uniq { |vers| vers[:number] }
    end
    packages
  end
end
