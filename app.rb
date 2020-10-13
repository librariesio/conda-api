# frozen_string_literal: true

require "sinatra/base"
require_relative "conda"
require_relative "app"
require "rufus-scheduler"

class CondaAPI < Sinatra::Base
  scheduler = Rufus::Scheduler.new

  get "/" do
    "Last updated at #{Conda.instance.main.timestamp} \n"
  end

  get "/packages" do
    content_type :json
    Conda.instance.all_packages.to_json
  end

  get "/package/:name" do
    content_type :json
    Conda.instance.find_package(params["name"]).to_json
  end

  get "/:channel/" do
    content_type :json
    Conda.instance.packages(params["channel"]).to_json
  end

  get "/:channel/:name" do
    content_type :json
    Conda.instance.package(params["channel"], params["name"]).to_json
  end

  scheduler.every "1h" do
    puts "Reloading packages..."
    Conda.instance.reload_all
    puts "Reload finished"
  end
end
