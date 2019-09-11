require 'bundler'
Bundler.require

require './conda'

redis_uri = ENV['REDIS_SERVER'] || 'localhost:6379'
client = Feedtosis::Client.new('http://repo.anaconda.com/pkgs/rss.xml',
                               backend: Moneta.new(:Redis,
                                                   host: URI.parse(redis_uri).host,
                                                   port: URI.parse(redis_uri).port))
loop do
  new_entries = client.fetch.new_entries
  if new_entries.length
    puts "#{new_entries.length} new"
    Conda.instance.update_packages
  end
  sleep 30
end
