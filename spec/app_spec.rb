# frozen_string_literal: true

describe CondaAPI do
  before do
    allow(Conda.instance).to receive(:download_json).and_return(json_load_fixture("pkgs/main.json"))
  end
  it "should show HelloWorld" do
    get "/"
    expect(last_response).to be_ok
  end

  it "should get list of packages" do
    get "/packages"
    expect(last_response).to be_ok

    json = JSON.parse(last_response.body)
    expect(json).to eq [
        "pkgs/main/urllib3",
        "pkgs/main/smart_open",
        "pkgs/main/six",
        "pkgs/main/sip",
    ]
  end
end
