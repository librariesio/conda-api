# frozen_string_literal: true

require "httparty"
require "json"
require "benchmark"

class Channel
  ARCHES = %w[linux-32 linux-64 linux-aarch64 linux-armv6l linux-armv7l linux-ppc64le osx-64 win-64 win-32 noarch zos-z].freeze

  attr_reader :timestamp

  def initialize(channel, domain)
    @channel_name = channel
    @domain = domain
    @timestamp = Time.now
    @lock = Concurrent::ReadWriteLock.new
    @packages = {}
  end

  def reload
    new_packages = retrieve_packages
    @lock.with_write_lock { @packages = new_packages }
    @timestamp = Time.now
  end

  def name
    @channel_name
  end

  def packages
    @lock.with_read_lock { @packages }
  end

  def package_version(name, version)
    @lock.with_read_lock do
      raise Sinatra::NotFound unless @packages.key?(name)

      @packages[name][:versions].filter { |package| package[:number] == version }
    end
  end

  def logger
    Conda.instance.logger
  end

  private

  def retrieve_packages
    packages = {}
    logger.info "Fetching packages for channel https://#{@domain}/#{@channel_name}..."
    channel_response = HTTParty.get("https://#{@domain}/#{@channel_name}/channeldata.json")
    channeldata = JSON.parse(channel_response.body)["packages"]

    benchmark = Benchmark.measure do
      ARCHES.each do |arch|
        repo_data_url = "https://#{@domain}/#{@channel_name}/#{arch}/repodata.json"
        response = HTTParty.get(repo_data_url)

        parsed_response = JSON.parse(response.body)

        blobs = [parsed_response["packages"], parsed_response["packages.conda"]]

        blobs.each do |blob|
          next if blob.nil?

          blob.each_pair do |artifact_filename, version|
            package_name = version["name"]

            if channeldata[package_name].nil?
              logger.info "Unable to get channel data for package #{package_name} from url: #{repo_data_url}"
              next
            end

            unless packages.key?(package_name)
              package_data = channeldata[package_name]
              packages[package_name] = base_package(package_data, package_name)
            end

            packages[package_name][:versions] << release_version(artifact_filename, version) unless packages[package_name][:versions].find { |v| v[:number] == version["version"] }
          end
        end
      rescue StandardError => e
        logger.info "Failed to fetch for #{arch} #{repo_data_url}. #{e.class}: #{e.message}"
      end
    end
    logger.info "Finished in #{benchmark.real.round(1)} sec: #{packages.to_json.bytesize / 1_000_000}mb of data."
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
end
