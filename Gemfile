# frozen_string_literal: true

source "https://rubygems.org"
ruby "2.5.0"

gem "builder"
gem "feedtosis", git: "https://github.com/alown/feedtosis"
gem "foreman"
gem "hiredis"
gem "httparty"
gem "moneta"
gem "msgpack"
gem "puma"
gem "redis"
gem "sinatra"

group :development do
  gem "capistrano"
end

group :test do
  gem "fakeredis", require: "fakeredis/rspec"
  gem "pry"
  gem "rack-test"
  gem "rspec"
end
