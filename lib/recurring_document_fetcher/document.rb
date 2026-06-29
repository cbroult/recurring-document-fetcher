# frozen_string_literal: true

module RecurringDocumentFetcher
  class Document
    CATEGORIES = %w[invoice statement call_log].freeze

    attr_reader :id, :provider, :date, :category, :filename, :url, :metadata, :original_filename

    # rubocop:disable Naming/MethodParameterName, Metrics/ParameterLists
    def initialize(id:, provider:, date:, category:, filename:, url:, metadata: {}, original_filename: nil)
      @id = id
      @provider = provider
      @date = date
      @category = category
      @filename = filename
      @url = url
      @metadata = metadata
      @original_filename = original_filename
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ParameterLists

    def ==(other)
      other.is_a?(self.class) && id == other.id && provider == other.provider
    end

    alias eql? ==

    def hash
      [id, provider].hash
    end

    def to_s
      "#{provider}/#{date}/#{filename}"
    end
  end
end
