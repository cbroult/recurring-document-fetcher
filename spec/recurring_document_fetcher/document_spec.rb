# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Document do
  subject(:document) do
    described_class.new(
      id: "INV-2026-01",
      provider: "telekom",
      date: Date.new(2026, 1, 15),
      category: "invoice",
      filename: "2026-01-15_telekom_INV-2026-01.pdf",
      url: "https://example.com/invoice.pdf",
      metadata: { amount: "29.99" }
    )
  end

  it "exposes all attributes" do
    expect(document.id).to eq("INV-2026-01")
    expect(document.provider).to eq("telekom")
    expect(document.date).to eq(Date.new(2026, 1, 15))
    expect(document.category).to eq("invoice")
    expect(document.filename).to eq("2026-01-15_telekom_INV-2026-01.pdf")
    expect(document.url).to eq("https://example.com/invoice.pdf")
    expect(document.metadata).to eq(amount: "29.99")
    expect(document.original_filename).to be_nil
  end

  it "accepts a custom original_filename" do
    doc = described_class.new(
      id: "INV-2026-01", provider: "telekom", date: Date.new(2026, 1, 15),
      category: "invoice", filename: "synth.pdf", url: "https://example.com",
      original_filename: "original_invoice.pdf"
    )
    expect(doc.original_filename).to eq("original_invoice.pdf")
  end

  it "is equal to another document with the same id and provider" do
    other = described_class.new(
      id: "INV-2026-01", provider: "telekom", date: Date.today,
      category: "invoice", filename: "other.pdf", url: "https://other.com"
    )
    expect(document).to eq(other)
  end

  it "is not equal to a document with a different id" do
    other = described_class.new(
      id: "INV-2026-02", provider: "telekom", date: Date.today,
      category: "invoice", filename: "other.pdf", url: "https://other.com"
    )
    expect(document).not_to eq(other)
  end

  it "returns a human-readable string" do
    expect(document.to_s).to eq("telekom/2026-01-15/2026-01-15_telekom_INV-2026-01.pdf")
  end
end
