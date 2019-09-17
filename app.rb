# frozen_string_literal: true

require "sinatra/base"
require_relative "conda"
require "builder"
require "cgi"

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
    if request.query_string.empty?
      {"error" => "Please provide at least a package name ?name= parameter"}.to_json
    else
      package_version(request.query_string)
    end
  end

  private

  def package_version(query_string)
    # Parse the query string for channel and name
    qs = CGI::parse(query_string)
    channel = qs["channel"].first || "pkgs/main"
    name = qs["name"].first || qs["package"].first

    package = Conda.instance.package(channel, name)
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end
end
