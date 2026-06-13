# frozen_string_literal: true

require "psych/pure"
require "fileutils"

module RecurringDocumentFetcher
  class Configuration
    DEFAULT_CONFIG_DIR = File.join(Dir.home, ".config", "recurring-document-fetcher")
    DEFAULT_CONFIG_PATH = File.join(DEFAULT_CONFIG_DIR, "config.yml")
    DEFAULT_DOWNLOAD_DIR = File.join(Dir.home, "Documents", "invoices")

    attr_reader :config_path, :data

    def self.load(config_path: DEFAULT_CONFIG_PATH)
      unless File.exist?(config_path)
        raise ConfigurationError,
              "Config file not found: #{config_path}. Run 'recurring-document-fetcher init' to create one."
      end

      data = Psych.safe_load_file(config_path, permitted_classes: [Date, Time]) || {}
      new(data:, config_path:)
    end

    def self.default_config_path
      DEFAULT_CONFIG_PATH
    end

    def initialize(data:, config_path: DEFAULT_CONFIG_PATH)
      @data = data
      @config_path = config_path
    end

    def download_dir
      File.expand_path(data.fetch("download_dir", DEFAULT_DOWNLOAD_DIR))
    end

    def headless?
      data.fetch("headless", true)
    end

    def rate_limit_seconds
      data.fetch("rate_limit_seconds", 2)
    end

    def providers
      data.fetch("providers", {})
    end

    def provider_config(name)
      providers.fetch(name.to_s) do
        raise ConfigurationError, "Provider '#{name}' not found in config. Available: #{providers.keys.join(", ")}"
      end
    end

    def provider_download_dir(provider_name)
      provider = providers[provider_name.to_s]
      if provider && provider["download_dir"]
        File.expand_path(provider["download_dir"])
      else
        File.join(download_dir, provider_name.to_s)
      end
    end
  end
end
