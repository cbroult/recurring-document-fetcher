# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::DocumentValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    it "accepts a valid PDF file" do
      path = File.join(Dir.tmpdir, "rdf_valid_#{Process.pid}.pdf")
      File.binwrite(path, "%PDF-1.4 #{"x" * 200}")

      result = validator.validate(path)
      expect(result).to be_valid
      expect(result.errors).to be_empty
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    it "rejects a nonexistent file" do
      result = validator.validate("/nonexistent/file.pdf")
      expect(result).not_to be_valid
      expect(result.errors.first).to include("does not exist")
    end

    it "rejects an empty file" do
      path = File.join(Dir.tmpdir, "rdf_empty_#{Process.pid}.pdf")
      File.write(path, "")

      result = validator.validate(path)
      expect(result).not_to be_valid
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    it "rejects a PDF with invalid header" do
      path = File.join(Dir.tmpdir, "rdf_bad_#{Process.pid}.pdf")
      File.binwrite(path, "NOT-A-PDF#{"x" * 200}")

      result = validator.validate(path)
      expect(result).not_to be_valid
      expect(result.errors).to include(/Invalid PDF/)
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    it "does not check PDF header for non-PDF files" do
      path = File.join(Dir.tmpdir, "rdf_csv_#{Process.pid}.csv")
      File.write(path, "col1,col2\nval1,val2\n#{"x" * 200}")

      result = validator.validate(path)
      expect(result).to be_valid
    ensure
      File.delete(path) if path && File.exist?(path)
    end
  end
end
