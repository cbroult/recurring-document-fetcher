# frozen_string_literal: true

module RecurringDocumentFetcher
  class DocumentValidator
    PDF_MAGIC_BYTES = "%PDF"
    MINIMUM_FILE_SIZE = 100

    Result = Struct.new(:valid, :errors, keyword_init: true) do
      alias_method :valid?, :valid
    end

    def validate(file_path)
      errors = []
      errors << "File does not exist: #{file_path}" unless File.exist?(file_path)
      return Result.new(valid: false, errors:) unless errors.empty?

      errors << "File is empty" if File.empty?(file_path)
      errors << "File too small (#{File.size(file_path)} bytes)" if File.size(file_path) < MINIMUM_FILE_SIZE

      if file_path.end_with?(".pdf")
        header = File.binread(file_path, 4)
        errors << "Invalid PDF: missing PDF header" unless header == PDF_MAGIC_BYTES
      end

      Result.new(valid: errors.empty?, errors:)
    end
  end
end
