# frozen_string_literal: true

require "fileutils"

module RecurringDocumentFetcher
  module Commands
    class Fetch
      # rubocop:disable Metrics/ParameterLists
      def initialize(configuration:, credential_store:, download_tracker:, document_validator:, provider_filter: nil,
                     force: false, output: $stdout)
        # rubocop:enable Metrics/ParameterLists
        @configuration = configuration
        @credential_store = credential_store
        @download_tracker = download_tracker
        @document_validator = document_validator
        @provider_filter = provider_filter
        @force = force
        @output = output
      end

      def call
        providers = resolve_providers
        if providers.empty?
          @output.puts "No providers configured."
          return []
        end

        results = []
        providers.each do |name, provider|
          results.concat(fetch_from_provider(name, provider))
        ensure
          provider.disconnect
        end
        results
      end

      private

      def resolve_providers
        provider_configs = @configuration.providers
        provider_configs = provider_configs.select { |k, _| k == @provider_filter } if @provider_filter

        provider_configs.each_with_object({}) do |(name, config), hash|
          merged_config = config.merge(
            "headless" => @configuration.headless?,
            "rate_limit_seconds" => @configuration.rate_limit_seconds
          )
          klass = Providers::Registry.resolve(config.fetch("type"))
          hash[name] = klass.new(config: merged_config, credential_store: @credential_store)
        end
      end

      def fetch_from_provider(name, provider)
        @output.puts "Fetching from #{name}..."
        provider.authenticate

        documents = provider.list_documents
        @output.puts "  Found #{documents.size} document(s)."

        downloaded = download_new_documents(name, provider, documents)
        @output.puts "  #{downloaded.size} new document(s) downloaded."
        downloaded
      rescue ProviderError, AuthenticationError => e
        @output.puts "  Error: #{e.message}"
        []
      end

      def download_new_documents(name, provider, documents)
        documents.each_with_object([]) do |doc, downloaded|
          next if !@force && @download_tracker.downloaded?(provider: name, document_id: doc.id)

          dest_path = download_document(name, provider, doc)
          track_and_validate(name, doc, dest_path)
          downloaded << doc
        end
      end

      def download_document(name, provider, doc)
        year_dir = File.join(@configuration.provider_download_dir(name), doc.date.year.to_s)
        FileUtils.mkdir_p(year_dir)
        dest_path = File.join(year_dir, doc.filename)
        provider.download(doc, destination: dest_path)
        dest_path
      end

      def track_and_validate(name, doc, dest_path)
        result = @document_validator.validate(dest_path)
        @download_tracker.record(
          provider: name, document_id: doc.id, document_date: doc.date,
          file_path: dest_path, file_size: File.size(dest_path)
        )

        if result.valid?
          @output.puts "  Downloaded: #{doc.filename}"
        else
          @download_tracker.mark_invalid(provider: name, document_id: doc.id)
          @output.puts "  Warning: #{doc.filename} - #{result.errors.join(", ")}"
        end
      end
    end
  end
end
