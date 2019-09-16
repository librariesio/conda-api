# frozen_string_literal: true

describe CondaAPI do
  before do
    allow(Conda.instance).to receive(:download_channeldata).and_return(json_load_fixture("pkgs/main.json"))
    Conda.instance.update_packages
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
      "pkgs/main/sip",
      "pkgs/main/six",
      "pkgs/main/smart_open",
      "pkgs/main/urllib3",
    ]
  end

  it "should get urllib3 both from channel and not" do
    get "/packages/pkgs/main/urllib3"
    expect(last_response).to be_ok

    json = JSON.parse(last_response.body)

    expected_full_response = {
      "activate.d" => false, 
      "binary_prefix" => false, 
      "deactivate.d" => false, 
      "description" => "urllib3 is a powerful, sanity-friendly HTTP client for Python. Much of the Python ecosystem already uses urllib3. urllib3 brings many critical features that are missing from the Python standard libraries, such as thread safety, connection pooling, client side ssl/tls verification, support for gzip and deflate encodings, HTTP and SOCKS proxy support, helpers for retrying requests and dealing with HTTP redirects.", 
      "dev_url" => "https://github.com/shazow/urllib3",
      "doc_source_url" => "https://github.com/shazow/urllib3/tree/master/docs",
      "doc_url" => "https://urllib3.readthedocs.io/",
      "home" => "https://urllib3.readthedocs.io/",
      "icon_url" => nil,
      "icon_hash" => nil,
      "identifiers" => nil,
      "keywords" => nil,
      "license" => "MIT",
      "post_link" => false,
      "pre_link" => false,
      "pre_unlink" => false,
      "recipe_origin" => nil,
      "run_exports" => {},
      "source_git_url" => nil,
      "source_url" => "https://pypi.io/packages/source/u/urllib3/urllib3-1.25.3.tar.gz",
      "subdirs" => ["linux-32", "linux-64", "linux-ppc64le", "osx-64", "win-32", "win-64"],
      "summary" => "HTTP library with thread-safe connection pooling, file post, and more.",
      "tags" => nil, 
      "text_prefix" => false, 
      "timestamp" => 1559851824, 
      "version" => "1.25.3"
    }

    expect(json).to eq expected_full_response

    get "/packages/urllib3"
    expect(last_response).to be_ok

    json = JSON.parse(last_response.body)
    expect(json).to eq expected_full_response
  end
end
