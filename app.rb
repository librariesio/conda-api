# frozen_string_literal: true

require "sinatra/base"
require "./conda_repo"
require "builder"

redis = Redis.new(url: ENV["REDIS_SERVER"], driver: :hiredis)
CONDA_REPO = CondaRepo.new(redis)
CONDA_REPO.update_packages

class CondaAPI < Sinatra::Base
  get "/" do
    "Hello World! #{CONDA_REPO.package_names.length} \n"
  end

  get "/packages.json" do
    content_type :json
    CONDA_REPO.package_names.to_json
  end

  get "/packages/:name.json" do
    content_type :json
    channel = "pkgs/main" # Default for now
    package = CONDA_REPO.package(channel, params[:name])
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end

  get %r{/packages/(.*)/(.*).json} do
    content_type :json

    channel = params[:captures].first
    name = params[:captures].last
    package = CONDA_REPO.package(channel, name)
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end
end
