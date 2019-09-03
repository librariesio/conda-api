require 'msgpack'
require 'json'
require 'redis'

class CondaRepo
  def initialize(redis_url = nil)
    @redis = Redis.new(url: redis_url, driver: :hiredis)
  end

  def package_names
    @redis.smembers("package_names")
  end

  def package(name)
    pack = @redis.get("packages:#{name}")
    return nil unless pack
    MessagePack.unpack(pack.force_encoding('ASCII-8BIT'))
  end

  def rss_entries
    git_history.split("\ncommit ").map do |entry|
      {
        guid: entry.gsub(/^.*commit /m, '').gsub(/\n.*$/m, '').strip,
        author_name: entry.gsub(/^.*Author: /m, '').gsub(/ <.*$/m, '').strip,
        date: entry.gsub(/^.*Date: +/m, '').gsub(/\n.*$/m, '').strip,
        comments: entry.gsub(/^.*Date[^\n]*/m, '').strip
      }
    end
  end

  def load_packages
    update_repo unless repo_cloned?

    files = Dir.glob("#{SPEC_PATH}/**/*.json")

    packages = {}

    files.each do |file|
      match = file.match(SPEC_REGEX)
      next unless match
      packages[match[1]] ||= {}
      packages[match[1]][match[2]] = file
    end
    packages
  end

  def write_packages_to_redis(packages)
    # push all names into set
    @redis.sadd('package_names', packages.keys)

    # write all the packages into keys
    packages.each_with_index do |(name, versions), index|
      versions.each { |k, v| versions[k] = JSON.parse(File.read(v)) }
      @redis.set("packages:#{name}", MessagePack.pack(versions))
      GC.start if index % 100 == 0
    end
  end

  def repo_cloned?
    File.directory?("#{SPEC_PATH}/.git")
  end

  def update_repo
    raise
  end

  def update_packages
    update_repo
    write_packages_to_redis load_packages
    nil
  end
end
