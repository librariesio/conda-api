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

  get "/packages/:name" do
    content_type :json
    package_version("pkgs/main", params[:name])
  end

  get "/packages/:channel/:name" do
    channel = CGI.unescape(CGI.unescape(params[:channel]))
    content_type :json
    package_version(channel, params[:name])
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
