# frozen_string_literal: true

require "httparty"
require "json"
require "msgpack"
require "singleton"

class Conda
  include Singleton

  CHANNEL_PATH = File.dirname(__FILE__) + "/tmp/channels"
  CHANNELS = [
    # channel, domain, directory_path_to channeldata.json
    ["pkgs/main", "repo.anaconda.com"],
    # ["conda-forge", "conda.anaconda.org", "/conda-forge"],
  ].freeze

  def initialize
    @redis = Redis.new(url: ENV["REDIS_SERVER"], driver: :hiredis)
  end

  def package_names
    @redis.smembers("package_names")
  end

  def package(channel, name)
    pack = @redis.get("packages:#{channel}/#{name}")
    return nil unless pack

    MessagePack.unpack(pack.force_encoding("ASCII-8BIT"))
  end

  def download_and_parse_packages
    channels_with_packages = {}
    CHANNELS.each do |channel, domain|
      channel_packages = download_json(channel, domain)["packages"]
      channels_with_packages[channel] ||= {}
      channel_packages.each do |package_name, package|
        channels_with_packages[channel][package_name] = package
      end
    end

    channels_with_packages
  end

  def update_packages
    download_and_parse_packages.each do |channel, packages|
      @redis.sadd("package_names", packages.keys.map { |name| "#{channel}/#{name}" })

      packages.each do |name, package_info|
        version = package_info["version"]
        key = "#{channel}/#{name}"
        @redis.set("packages:#{key}", MessagePack.pack(version))
      end
    end
  end

  private

  def download_json(channel, domain)
    url = "https://#{domain}/#{channel}/channeldata.json"
    HTTParty.get(url).parsed_response
  end
end
