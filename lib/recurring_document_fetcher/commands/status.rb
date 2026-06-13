# frozen_string_literal: true

module RecurringDocumentFetcher
  module Commands
    class Status
      def initialize(download_tracker:, provider: nil, since: nil, output: $stdout)
        @download_tracker = download_tracker
        @provider = provider
        @since = since
        @output = output
      end

      def call
        entries = @download_tracker.history(provider: @provider, since: @since)

        if entries.empty?
          @output.puts "No downloads recorded."
          return
        end

        @output.puts "Download history (#{entries.size} entries):"
        @output.puts ""

        entries.each do |entry|
          status = entry[:valid] ? "OK" : "INVALID"
          filename = File.basename(entry[:file_path])
          @output.puts "  [#{status}] #{entry[:provider]} | #{entry[:document_date]} | #{filename}"
        end
      end
    end
  end
end
