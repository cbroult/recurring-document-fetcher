# frozen_string_literal: true

module RecurringDocumentFetcher
  module Providers
    class Base
      DEFAULT_RATE_LIMIT_SECONDS = 2

      attr_reader :config, :credential_store

      def initialize(config:, credential_store:)
        @config = config
        @credential_store = credential_store
        @last_request_at = nil
      end

      def authenticate
        raise NotImplementedError, "#{self.class}#authenticate must be implemented"
      end

      def list_documents
        raise NotImplementedError, "#{self.class}#list_documents must be implemented"
      end

      def download(document, destination:)
        raise NotImplementedError, "#{self.class}#download must be implemented"
      end

      def disconnect
        # Override in subclasses if cleanup is needed
      end

      private

      def rate_limit_seconds
        config.fetch("rate_limit_seconds", DEFAULT_RATE_LIMIT_SECONDS)
      end

      def with_rate_limit
        if @last_request_at
          elapsed = Time.now - @last_request_at
          sleep(rate_limit_seconds - elapsed) if elapsed < rate_limit_seconds
        end
        result = yield
        @last_request_at = Time.now
        result
      end

      def provider_name
        self.class.name.split("::").last.downcase
      end
    end
  end
end
