# frozen_string_literal: true

module RecurringDocumentFetcher
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class_option :config, aliases: "-c", type: :string, desc: "Path to config file"

    desc "version", "Show recurring-document-fetcher version"
    def version
      say "recurring-document-fetcher #{RecurringDocumentFetcher::VERSION}"
    end

    desc "fetch", "Fetch documents from configured providers"
    option :provider, aliases: "-p", type: :string, desc: "Fetch from a specific provider only"
    option :force, aliases: "-f", type: :boolean, default: false, desc: "Force re-download of all documents"
    def fetch
      config = build_config
      Commands::Fetch.new(
        configuration: config,
        credential_store: build_credential_store,
        download_tracker: build_download_tracker,
        document_validator: DocumentValidator.new,
        provider_filter: options[:provider],
        force: options[:force]
      ).call
    rescue RecurringDocumentFetcher::Error => e
      abort_with(e.message)
    end

    desc "init", "Generate a config file template"
    def init
      config_path = resolve_config_path
      path = Commands::Init.new(config_path).call
      say "Config file created at #{path}"
      say "  Edit it with your provider settings, then run:"
      say "  recurring-document-fetcher credentials store <provider_name>"
      say "  recurring-document-fetcher fetch"
    rescue RecurringDocumentFetcher::Error => e
      abort_with(e.message)
    end

    desc "status", "Show download history"
    option :provider, aliases: "-p", type: :string, desc: "Filter by provider"
    option :since, type: :string, desc: "Show downloads since date (YYYY-MM-DD)"
    def status
      Commands::Status.new(
        download_tracker: build_download_tracker,
        provider: options[:provider],
        since: options[:since]
      ).call
    rescue RecurringDocumentFetcher::Error => e
      abort_with(e.message)
    end

    desc "credentials SUBCOMMAND", "Manage provider credentials"
    subcommand "credentials", Class.new(Thor) {
      def self.exit_on_failure?
        true
      end

      desc "store PROVIDER", "Store credentials for a provider"
      def store(provider_name)
        credential_store = CredentialStore.new
        Commands::Credentials.new(credential_store:).store(provider_name)
      rescue RecurringDocumentFetcher::Error => e
        warn "Error: #{e.message}"
        exit 1
      end

      desc "list", "List providers with stored credentials"
      def list
        credential_store = CredentialStore.new
        Commands::Credentials.new(credential_store:).list
      rescue RecurringDocumentFetcher::Error => e
        warn "Error: #{e.message}"
        exit 1
      end

      desc "delete PROVIDER", "Delete credentials for a provider"
      def delete(provider_name)
        credential_store = CredentialStore.new
        Commands::Credentials.new(credential_store:).delete(provider_name)
      rescue RecurringDocumentFetcher::Error => e
        warn "Error: #{e.message}"
        exit 1
      end
    }

    private

    def abort_with(message)
      warn "Error: #{message}"
      exit 1
    end

    def resolve_config_path
      options[:config] || Configuration.default_config_path
    end

    def build_config
      Configuration.load(config_path: resolve_config_path)
    end

    def build_credential_store
      CredentialStore.new
    end

    def build_download_tracker
      DownloadTracker.new
    end
  end
end
