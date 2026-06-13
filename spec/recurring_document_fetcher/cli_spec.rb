# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::CLI do
  describe ".exit_on_failure?" do
    it "returns true" do
      expect(described_class.exit_on_failure?).to be true
    end
  end
end
