# frozen_string_literal: true

RSpec.describe Conda do
  describe "Conda" do
    subject { described_class.instance }
    before do
      allow(subject).to receive(:download_json).and_return(json_load_fixture("pkgs/main.json"))
    end

    it "loads packages" do
      packages = subject.download_and_parse_packages
      expect(packages["pkgs/main"].count).to be 58
    end

    describe "with redis" do
      before do
        subject.update_packages
      end

      it "writes to redis and gets a version back" do
        expect(subject.package("pkgs/main", "urllib3")).to eq "1.25.3"
      end

      it "shows a list of packages" do
        expect(subject.package_names).to include "pkgs/main/urllib3"
        expect(subject.package_names).to include "pkgs/main/smart_open"
        expect(subject.package_names).to include "pkgs/main/six"
        expect(subject.package_names).to include "pkgs/main/sip"
      end
    end
  end
end
