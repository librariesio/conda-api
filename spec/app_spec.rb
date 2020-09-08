# frozen_string_literal: true

describe CondaAPI do
  before do
    allow(Conda.instance.main).to receive(:reload)
    allow(HTTParty).to receive(:get).and_return(json_load_fixture("pkgs/repodata.json"))
  end

  it "should show HelloWorld" do
    Conda.instance.main.reload
    get "/"
    expect(last_response).to be_ok
  end

  it "should get list of packages" do
    Conda.instance.main.reload
    get "/packages"
    expect(last_response).to be_ok
    json = JSON.parse(last_response.body)
    expect(json.keys.length).to eq 1877
    expect(json.keys[12]).to eq "absl-py"
  end

  it "should 404 on missing package" do
    Conda.instance.main.reload
    get "/package/something-fake"
    expect(last_response).to be_not_found
  end
end
