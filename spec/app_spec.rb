# frozen_string_literal: true

describe CondaAPI do
  before do
    stub_request(:get, /repo.anaconda.com/).to_return({ status: 200, body: "{}" })
    stub_request(:get, /conda.anaconda.org/).to_return({ status: 200, body: "{}" })
    # needs to be after the default webmock stubs
    stub_request(:get,
                 "https://conda.anaconda.org/conda-forge/channeldata.json")
      .to_return({
                   status: 200,
                   body: load_fixture("pkgs/conda-forge/channeldata-small.json"),
                 })
    stub_request(:get,
                 "https://conda.anaconda.org/conda-forge/linux-64/repodata.json")
      .to_return({
                   status: 200,
                   body: load_fixture("pkgs/conda-forge/linux-64-repodata-small.json"),
                 })
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
