# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Configuration do
  describe ".load" do
    it "raises ConfigurationError when file does not exist" do
      expect { described_class.load(config_path: "/nonexistent/config.yml") }
        .to raise_error(RecurringDocumentFetcher::ConfigurationError, /Config file not found/)
    end

    it "loads a valid config file" do
      config_path = File.join(Dir.tmpdir, "rdf_test_config_#{Process.pid}.yml")
      File.write(config_path, <<~YAML)
        download_dir: /tmp/invoices
        providers:
          test:
            type: handyvertrag
            username: "0157123"
      YAML

      config = described_class.load(config_path:)
      expect(config.download_dir).to eq("/tmp/invoices")
      expect(config.providers).to have_key("test")
    ensure
      File.delete(config_path) if config_path && File.exist?(config_path)
    end
  end

  describe "defaults" do
    subject(:config) { described_class.new(data: {}) }

    it "uses default download dir" do
      expect(config.download_dir).to eq(File.expand_path("~/Documents/invoices"))
    end

    it "defaults to headless mode" do
      expect(config.headless?).to be true
    end

    it "defaults to 2 second rate limit" do
      expect(config.rate_limit_seconds).to eq(2)
    end

    it "returns empty providers when none configured" do
      expect(config.providers).to eq({})
    end
  end

  describe "#provider_download_dir" do
    subject(:config) { described_class.new(data: { "download_dir" => "/tmp/invoices", "providers" => providers }) }

    let(:providers) { { "telekom" => { "type" => "telekom" } } }

    it "derives subdirectory from provider name" do
      expect(config.provider_download_dir("telekom")).to eq("/tmp/invoices/telekom")
    end

    context "when provider has custom download_dir" do
      let(:providers) { { "telekom" => { "type" => "telekom", "download_dir" => "/custom/path" } } }

      it "uses the custom path" do
        expect(config.provider_download_dir("telekom")).to eq("/custom/path")
      end
    end
  end
end
