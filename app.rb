# frozen_string_literal: true

require "sinatra/base"
require_relative "conda"
require_relative "app"
require "rufus-scheduler"

class CondaAPI < Sinatra::Base
  register Sinatra::SensibleLogging

  configure :production, :development do
    # use SensibleLogging for request id, request logging, and tagged logging
    sensible_logging(
      logger: Logger.new($stdout),
      log_tags: [->(_req) { [Time.now] }]
    )
    set :log_level, Logger::INFO
  end

  configure do
    set :dump_errors, false
    set :raise_errors, true
    set :show_exceptions, false
  end

  get "/" do
    "Last updated at #{Conda.instance.channels.values.first.timestamp} \n"
  end

  get "/healthcheck" do
    if Conda.instance.packages.empty?
      error(503, "Not ready yet")
    else
      "OK"
    end
  end

  get "/stats.json" do
    Conda.instance.channels.values.map do |channel|
      {
        name: channel.name,
        last_updated: channel.timestamp,
        packages: channel.packages.length,
      }
    end.to_json
  end

  get "/packages" do
    content_type :json
    Conda.instance.packages.to_json
  end

  get "/package/:name" do
    content_type :json
    Conda.instance.find_package(params["name"]).to_json
  end

  get "/package/:name/:version" do
    content_type :json
    package = Conda.instance.find_package(params["name"]).clone
    package[:versions] = package[:versions].select { |version| version[:number] == params["version"] }
    package.to_json
  end

  get "/:channel/" do
    content_type :json
    Conda.instance.packages_by_channel(params["channel"]).to_json
  end

  get "/:channel/:name" do
    content_type :json
    Conda.instance.package(params["channel"], params["name"]).to_json
  end

  get "/:channel/:name/:version" do
    content_type :json
    Conda.instance.package_by_channel(params["channel"], params["name"], params["version"]).to_json
  end
end
