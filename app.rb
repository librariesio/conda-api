require 'sinatra/base'
require './conda_repo'
require 'builder'

CONDA_REPO = CondaRepo.new(ENV['REDIS_SERVER'])

class CondaAPI < Sinatra::Base
  get '/' do
    "Hello World! #{CONDA_REPO.package_names.length} \n"
  end

  get '/packages.json' do
    content_type :json
    CONDA_REPO.package_names.to_json
  end

  get '/packages/:name.json' do
    content_type :json
    package = CONDA_REPO.package(params[:name])
    if package
      package.to_json
    else
      halt 404, "Product not found"
    end
  end

  get '/feed.rss' do
    @entries = CONDA_REPO.rss_entries
    builder :rss
  end
end
