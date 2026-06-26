# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Providers::Registry do
  around do |example|
    saved = described_class.send(:registry).dup
    described_class.clear
    example.run
    described_class.send(:registry).replace(saved)
  end

  let(:dummy_class) { Class.new(RecurringDocumentFetcher::Providers::Base) }

  describe ".register and .resolve" do
    it "registers and resolves a provider type" do
      described_class.register("test_provider", dummy_class)
      expect(described_class.resolve("test_provider")).to eq(dummy_class)
    end
  end

  describe ".resolve with unknown type" do
    it "raises ProviderError" do
      expect { described_class.resolve("unknown") }
        .to raise_error(RecurringDocumentFetcher::ProviderError, /Unknown provider type: unknown/)
    end
  end

  describe ".registered_types" do
    it "returns sorted list of registered types" do
      described_class.register("beta", dummy_class)
      described_class.register("alpha", dummy_class)
      expect(described_class.registered_types).to eq(%w[alpha beta])
    end
  end
end
