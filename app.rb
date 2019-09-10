# frozen_string_literal: true

require "sinatra/base"
require "./conda"
require "builder"

redis = Redis.new(url: ENV["REDIS_SERVER"], driver: :hiredis)
CONDA = Conda.new(redis)
CONDA.update_packages

class CondaAPI < Sinatra::Base
  get "/" do
    "Hello World! #{CONDA.package_names.length} \n"
  end

  get "/packages" do
    content_type :json
    CONDA.package_names.to_json
  end

  get "/packages/:name" do
    content_type :json
    channel = "pkgs/main" # Default for now
    package_version(channel, name)
  end

  get %r{/packages/(?<channel>.*)/(?<name>.*)/?} do
    content_type :json
    package_version(params[:channel], params[:name])
  end

  private

  def package_version(channel, name)
    package = CONDA.package(channel, name)
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end
end
