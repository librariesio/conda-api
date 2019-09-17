# frozen_string_literal: true

require "sinatra/base"
require_relative "conda"
require "builder"

class CondaAPI < Sinatra::Base
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
