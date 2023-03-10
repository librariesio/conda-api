# frozen_string_literal: true

describe Channel do
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
  end

  subject(:channel) { described_class.new("conda-forge", "conda.anaconda.org") }

  describe "#packages" do
    context "when there is one arch source" do
      before do
        stub_request(:get,
                     "https://conda.anaconda.org/conda-forge/noarch/repodata.json")
          .to_return({
                       status: 200,
                       body: load_fixture("pkgs/conda-forge/noarch-repodata-small.json"),
                     })
      end

      it "gets all the packages that have channel data from the one available arch source" do
        packages = channel.packages
        expect(packages.count).to eq(10)

        expect(packages.keys).to include(
          "_current_repodata_hack_gcc_linux_64_75",
          "_current_repodata_hack_gcc_linux_64_84",
          "_current_repodata_hack_gcc_linux_aarch64_75",
          "_current_repodata_hack_gcc_linux_aarch64_84",
          "_current_repodata_hack_gcc_linux_ppc64le_75",
          "_current_repodata_hack_gcc_linux_ppc64le_84",
          "ansible-core",
          "black",
          "about-time",
          "absl-py"
        )
      end

      it "does not get packages that do not have channel data" do
        packages = channel.packages

        # these appear to only be in the packages.conda folder & not in the packages folder
        expect(packages.keys).to_not include("baked-brie", "django-safedelete", "pygwalker")
      end

      context "when there are multiple arch sources" do
        before do
          stub_request(:get,
                       "https://conda.anaconda.org/conda-forge/linux-64/repodata.json")
            .to_return({
                         status: 200,
                         body: load_fixture("pkgs/conda-forge/linux-64-repodata-small.json"),
                       })
        end

        it "gets all the packages that have channel data from all arch sources" do
          packages = channel.packages
          expect(packages.count).to eq(14)

          # from the linux-64 file
          expect(packages.keys).to include("21cmfast", "black", "zziplib", "4ti2", "abess")
          # from the noarch file
          expect(packages.keys).to include(
            "_current_repodata_hack_gcc_linux_64_75",
            "_current_repodata_hack_gcc_linux_64_84",
            "_current_repodata_hack_gcc_linux_aarch64_75",
            "_current_repodata_hack_gcc_linux_aarch64_84",
            "_current_repodata_hack_gcc_linux_ppc64le_75",
            "_current_repodata_hack_gcc_linux_ppc64le_84",
            "ansible-core",
            "black", # note that this does not get counted twice
            "about-time",
            "absl-py"
          )
        end
      end
    end
  end

  describe "#package_version" do
    before do
      stub_request(:get,
                   "https://conda.anaconda.org/conda-forge/noarch/repodata.json")
        .to_return({
                     status: 200,
                     body: load_fixture("pkgs/conda-forge/noarch-repodata-small.json"),
                   })
    end

    subject(:channel) { described_class.new("conda-forge", "conda.anaconda.org") }

    let(:package_name) { "ansible-core" }
    let(:versions_bz2) do
      [
        "2.11.0",
        "2.11.1",
        "2.11.2",
        "2.11.3",
        "2.11.4",
        "2.11.5",
        "2.11.6",
        "2.12.0",
        "2.12.1",
        "2.12.2",
        "2.12.3",
        "2.12.4",
        "2.12.5",
        "2.13.0",
        "2.13.1",
        "2.13.2",
        "2.13.3",
        "2.13.4",
        "2.13.5",
        "2.14.0",
      ]
    end
    let(:versions_conda) do
      [
        "2.14.1",
        "2.14.2",
        "2.14.3",
      ]
    end

    it "returns information about a package + version distributed in .bz2 format" do
      actual = channel.package_version(package_name, "2.12.5")

      expect(actual.first).to include(
        artifact: "ansible-core-2.12.5-pyhd8ed1ab_0.tar.bz2",
        download_url: "https://conda.anaconda.org/conda-forge/noarch/ansible-core-2.12.5-pyhd8ed1ab_0.tar.bz2",
        original_license: "GPL-3.0-or-later",
        published_at: instance_of(Time),
        dependencies: ["cryptography", "jinja2", "packaging", "python >=3.5", "pyyaml", "resolvelib <0.6.0,>=0.5.3"],
        arch: "noarch",
        channel: "conda-forge",
        number: "2.12.5"
      )
    end

    it "returns information about a package + all of its version distributed in .bz2 format" do
      versions_bz2.each do |version|
        expect(channel.package_version(package_name, version)).to_not be_empty
      end
    end

    it "returns information about a package + version distributed in .conda format" do
      actual = channel.package_version(package_name, "2.14.3")

      expect(actual.first).to include(
        artifact: "ansible-core-2.14.3-pyhd8ed1ab_0.conda",
        download_url: "https://conda.anaconda.org/conda-forge/noarch/ansible-core-2.14.3-pyhd8ed1ab_0.conda",
        original_license: "GPL-3.0-or-later",
        published_at: instance_of(Time),
        dependencies: ["cryptography", "jinja2 >=3.0", "packaging", "python >=3.8", "pyyaml", "resolvelib <0.6.0,>=0.5.3"],
        arch: "noarch",
        channel: "conda-forge",
        number: "2.14.3"
      )
    end

    it "returns information about a package + all of its versions distributed in .conda format" do
      versions_conda.each do |version|
        expect(channel.package_version(package_name, version)).to_not be_empty
      end
    end

    it "raises an error for a package that doesn't exist" do
      expect do
        channel.package_version("#{package_name}_123", versions_bz2.first)
      end.to raise_error(Sinatra::NotFound)
    end

    it "returns an empty array for a package that exists + version that does not exist" do
      expect(channel.package_version(package_name, "#{versions_bz2.first}123")).to eq([])
    end
  end
end
