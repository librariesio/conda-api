require 'bundler'
Bundler.require

require './conda_repo'

redis_uri = ENV['REDIS_SERVER'] || 'localhost:6379'
client = Feedtosis::Client.new('http://github.com/Conda/Specs/commits/master.atom',
                               backend: Moneta.new(:Redis,
                                                   host: URI.parse(redis_uri).host,
                                                   port: URI.parse(redis_uri).port))
while(true) do
  new_entries = client.fetch.new_entries
  CondaRepo.new(redis_uri).update_packages if new_entries
  sleep 30
end
