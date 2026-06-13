# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::DownloadTracker do
  subject(:tracker) { described_class.new(db_path: ":memory:") }

  let(:test_file) do
    path = File.join(Dir.tmpdir, "rdf_test_#{Process.pid}.pdf")
    File.write(path, "%PDF-1.4 test content here for checksum")
    path
  end

  after do
    tracker.close
    FileUtils.rm_f(test_file)
  end

  describe "#record and #downloaded?" do
    it "tracks a downloaded document" do
      tracker.record(
        provider: "telekom", document_id: "INV-001",
        document_date: Date.new(2026, 1, 15), file_path: test_file, file_size: File.size(test_file)
      )
      expect(tracker.downloaded?(provider: "telekom", document_id: "INV-001")).to be true
      expect(tracker.downloaded?(provider: "telekom", document_id: "INV-002")).to be false
    end
  end

  describe "#history" do
    before do
      tracker.record(provider: "telekom", document_id: "INV-001",
                     document_date: Date.new(2026, 1, 15), file_path: test_file, file_size: 1000)
      tracker.record(provider: "blau", document_id: "INV-002",
                     document_date: Date.new(2026, 2, 1), file_path: test_file, file_size: 2000)
    end

    it "returns all entries" do
      expect(tracker.history.size).to eq(2)
    end

    it "filters by provider" do
      entries = tracker.history(provider: "telekom")
      expect(entries.size).to eq(1)
      expect(entries.first[:provider]).to eq("telekom")
    end
  end

  describe "#mark_invalid" do
    it "flags a document as invalid" do
      tracker.record(provider: "test", document_id: "DOC-1",
                     document_date: Date.today, file_path: test_file, file_size: 100)
      tracker.mark_invalid(provider: "test", document_id: "DOC-1")

      entry = tracker.history.first
      expect(entry[:valid]).to be false
    end
  end

  describe "#mark_for_redownload" do
    it "removes the download record" do
      tracker.record(provider: "test", document_id: "DOC-1",
                     document_date: Date.today, file_path: test_file, file_size: 100)
      tracker.mark_for_redownload(provider: "test", document_id: "DOC-1")

      expect(tracker.downloaded?(provider: "test", document_id: "DOC-1")).to be false
    end
  end
end
