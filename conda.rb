# frozen_string_literal: true

require "httparty"
require "json"
require "msgpack"
require "singleton"

class Conda
  include Singleton

  CHANNELS = [
    # channel, domain, directory_path_to channeldata.json
    ["pkgs/main", "repo.anaconda.com"],
    # TODO: enable me when asked to.
    # ["conda-forge", "conda.anaconda.org", "/conda-forge"],
  ].freeze

  def initialize
    if ENV["RACK_ENV"] == "test"
      @redis = MockRedis.new
    else
      @redis = Redis.new(url: ENV["REDIS_SERVER"], driver: :hiredis)
    end
  end

  ###########
  # Getters # -> Used for Api Calls
  ###########

  def package_names
    @redis.smembers("package_names").sort
  end

  def package(channel, name)
    pack = @redis.get("packages:#{channel}/#{name}")
    return unless pack

    MessagePack.unpack(pack.force_encoding("ASCII-8BIT")).update({"name" => name})
  end

  def latest(count)
    packages = @redis.scan_each(match: "packages:*").to_a.map do |key|
      channel, name = channel_and_name_from_key(key)
      package = package(channel, name)
      next if package["timestamp"].nil?

      {name: name, channel: channel, timestamp: package["timestamp"]}
    end.compact

    packages.sort_by{|p| p[:timestamp]}.reverse[0...count]
  end

  ###########
  # Setters # -> Things to set up the data
  ###########

  def update_packages
    download_and_parse_packages.each do |channel, packages|
      @redis.sadd("package_names", packages.keys.map { |name| "#{channel}/#{name}" })
      packages.each do |name, package_info|
        version = package_info["version"]
        key = "packages:#{channel}/#{name}"
        @redis.set(key, MessagePack.pack(package_info))
      end
    end
  end

  def download_and_parse_packages
    channels_with_packages = {}
    CHANNELS.each do |channel, domain|
      channel_packages = download_channeldata(channel, domain)["packages"]
      channels_with_packages[channel] ||= {}
      channel_packages.each do |package_name, package|
        channels_with_packages[channel][package_name] = package
      end
    end

    channels_with_packages
  end

  private

  def download_channeldata(channel, domain)
    url = "https://#{domain}/#{channel}/channeldata.json"
    HTTParty.get(url).parsed_response
  end

  def channel_and_name_from_key(key)
    # Split apart the channel and name from the redis key `packages:channel/name`
    channel, _, name = key.rpartition(":").last.rpartition("/")

    [channel, name]
  end
end
