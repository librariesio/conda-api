# frozen_string_literal: true

RSpec.describe Conda do
  describe "Conda" do
    subject { described_class.instance }
    before do
      allow(subject).to receive(:download_channeldata).and_return(json_load_fixture("pkgs/main.json"))
    end

    it "loads packages" do
      packages = subject.download_and_parse_packages
      expect(packages["pkgs/main"].count).to be 4
    end

    describe "with redis" do
      before do
        subject.update_packages
      end

      it "writes to redis and gets a version back" do
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
          "name" => "urllib3",
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

        expect(subject.package("pkgs/main", "urllib3")).to eq expected_full_response
      end

      it "shows a list of packages" do
        expect(subject.package_names).to eq [
          "pkgs/main/sip",
          "pkgs/main/six",
          "pkgs/main/smart_open",
          "pkgs/main/urllib3",
        ]
      end

      it "gets latest X packages" do
        # We have 4 in fixture, so picked 3 so that one would NOT be there
        expect(subject.latest 3).to eq [
          {channel: "pkgs/main", name: "smart_open", timestamp: 1559917931},
          {channel: "pkgs/main", name: "urllib3", timestamp: 1559851824},
          {channel: "pkgs/main", name: "six", timestamp: 1544543226}
        ]
      end
    end
  end
end
