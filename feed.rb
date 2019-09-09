require 'bundler'
Bundler.require

require './conda_repo'

# redis_uri = ENV['REDIS_SERVER'] || 'localhost:6379'
# client = Feedtosis::Client.new('https://repo.anaconda.com/pkgs/rss.xml',
#                                backend: Moneta.new(:Redis,
#                                                    host: URI.parse(redis_uri).host,
#                                                    port: URI.parse(redis_uri).port))
# TODO: do this in next PR
#while(true) do
#  new_entries = client.fetch.new_entries
#  CocoapodsRepo.new(redis_uri).update_pods if new_entries
#  sleep 30
#end
