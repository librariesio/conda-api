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
    Conda.instance.main.packages.to_json
  end

  get "/package/:name" do
    content_type :json
    if params["name"] && Conda.instance.main.packages.has_key?(params["name"])
      Conda.instance.main.packages[params["name"]].to_json
    else
      raise Sinatra::NotFound
    end
  end

  scheduler.every '1h' do
    puts "Reloading packages..."
    Conda.instance.main.reload
    puts "Reload finished"
  end
end
