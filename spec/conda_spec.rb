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
        expect(subject.package("pkgs/main", "urllib3")).to eq "1.25.3"
      end

      it "shows a list of packages" do
        expect(subject.package_names).to eq [
          "pkgs/main/sip",
          "pkgs/main/six",
          "pkgs/main/smart_open",
          "pkgs/main/urllib3",
        ]
      end
    end
  end
end
