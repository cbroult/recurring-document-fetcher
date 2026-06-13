# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Providers::Base do
  subject(:provider) do
    described_class.new(config: config, credential_store: credential_store)
  end

  let(:config) { { "rate_limit_seconds" => 1 } }
  let(:credential_store) { instance_double(RecurringDocumentFetcher::CredentialStore) }

  describe "#authenticate" do
    it "raises NotImplementedError" do
      expect { provider.authenticate }.to raise_error(NotImplementedError)
    end
  end

  describe "#list_documents" do
    it "raises NotImplementedError" do
      expect { provider.list_documents }.to raise_error(NotImplementedError)
    end
  end

  describe "#download" do
    it "raises NotImplementedError" do
      doc = instance_double(RecurringDocumentFetcher::Document)
      expect { provider.download(doc, destination: "/tmp/test") }.to raise_error(NotImplementedError)
    end
  end

  describe "#disconnect" do
    it "does not raise" do
      expect { provider.disconnect }.not_to raise_error
    end
  end
end
