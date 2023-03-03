# frozen_string_literal: true

describe CondaAPI do
  before do
    allow(HTTParty).to receive(:get).and_return({})
    allow(HTTParty).to receive(:get).with("https://conda.anaconda.org/conda-forge/channeldata.json")
      .and_return(
        json_load_fixture("pkgs/conda-forge/channeldata-small.json")
      )
    allow(HTTParty).to receive(:get).with("https://conda.anaconda.org/conda-forge/linux-64/repodata.json")
      .and_return(
        json_load_fixture("pkgs/conda-forge/linux-64-repodata-small.json")
      )
  end

  it "should show HelloWorld" do
    Conda.instance
    get "/"
    expect(last_response).to be_ok
  end

  it "should get a list of packages" do
    Conda.instance

    get "/packages"
    expect(last_response).to be_ok

    json = JSON.parse(last_response.body)
    expect(json.keys.length).to eq(5)
    # third item in the channeldata.json file
    expect(json.keys).to include("4ti2", "21cmfast", "black", "zziplib", "abess")
  end

  it "should 404 on missing package" do
    Conda.instance

    get "/package/something-fake"
    expect(last_response).to be_not_found
  end
end
