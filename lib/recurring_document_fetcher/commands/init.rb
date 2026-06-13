# frozen_string_literal: true

require "fileutils"

module RecurringDocumentFetcher
  module Commands
    class Init
      TEMPLATE = <<~YAML
        # Recurring Document Fetcher configuration
        # See: https://github.com/cbroult/recurring-document-fetcher

        download_dir: ~/Documents/invoices
        rate_limit_seconds: 2
        headless: true

        providers:
          # Mobile providers (Telefónica family)
          # handyvertrag:
          #   type: handyvertrag
          #   username: "015712345678"

          # blau:
          #   type: blau
          #   username: "015798765432"

          # Telekom
          # telekom:
          #   type: telekom
          #   username: "my.email@example.com"

          # Banking
          # amex:
          #   type: amex
          #   username: "my.email@example.com"
          #   mfa_method: authenticator

          # targobank:
          #   type: targobank
          #   account_number: "1234567890"
          #   tan_method: easytan

          # n26:
          #   type: n26
          #   username: "my.email@example.com"

          # revolut:
          #   type: revolut
          #   username: "+4915712345678"
          #   formats: [pdf, csv]

          # Utility providers
          # my_stadtwerke:
          #   type: utility
          #   preset: vattenfall
          #   username: "V123456789"
      YAML

      def initialize(config_path)
        @config_path = config_path
      end

      def call
        raise ConfigurationError, "Config file already exists: #{@config_path}" if File.exist?(@config_path)

        FileUtils.mkdir_p(File.dirname(@config_path))
        File.write(@config_path, TEMPLATE)
        @config_path
      end
    end
  end
end
