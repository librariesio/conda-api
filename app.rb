# frozen_string_literal: true

require "sinatra/base"
require_relative "conda"
require_relative "app"

class CondaAPI < Sinatra::Base
  NUM_RECENT_PACKAGES = 25

  get "/" do
    "Hello World! #{Conda.instance.package_names.length} \n"
  end

  get "/packages" do
    content_type :json
    Conda.instance.package_names.to_json
  end

  get "/package" do
    content_type :json
    unless params["name"]
      {"error" => "Please provide at least a package name ?name= parameter"}.to_json
    else
      package_version(params["channel"] || "pkgs/main", params["name"])
    end
  end

  get '/feed.json' do
    content_type :json

    Conda.instance.latest(NUM_RECENT_PACKAGES).map { |x| x[:name] }.to_json
  end

  get '/feed.rss' do
    content_type :rss

    @entries = Conda.instance.latest(NUM_RECENT_PACKAGES)
    builder :rss
  end

  private

  def package_version(channel, name)
    package = Conda.instance.package(channel, name)
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end
end
