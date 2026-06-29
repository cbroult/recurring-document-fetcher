# frozen_string_literal: true

require "fileutils"
require "psych/pure"

module RecurringDocumentFetcher
  module Commands
    class Configure
      def initialize(config_path:, credential_store:, output: $stdout, input: $stdin)
        @config_path = config_path
        @credential_store = credential_store
        @output = output
        @input = input
      end

      def list
        @output.puts "Available provider types:"
        Providers::Registry.registered_types.each do |type|
          klass = Providers::Registry.resolve(type)
          fields = klass.config_fields
          @output.puts "  #{type}"
          fields.each do |field|
            required = field.required ? " (required)" : ""
            secret = field.secret ? " [secret]" : ""
            @output.puts "    #{field.cli_flag}: #{field.label}#{required}#{secret}"
          end
          @output.puts
        end
      end

      def call(provider_type = nil, cli_options: {}, force: false)
        provider_type ||= pick_provider_interactively
        return unless provider_type

        klass = Providers::Registry.resolve(provider_type)
        fields = klass.config_fields

        config = load_or_create_config
        provider_name = resolve_provider_name(provider_type, cli_options)

        check_existing!(config, provider_name, provider_type, force)

        config_entry = build_config_entry(provider_type, fields, cli_options)
        handle_download_dir(config_entry, cli_options)
        config["providers"] ||= {}
        config["providers"][provider_name] = config_entry

        save_config(config)
        @output.puts "Configured '#{provider_name}' (#{provider_type})."
        @output.puts "You can now run: recurring-document-fetcher fetch"
      end

      private

      def pick_provider_interactively
        types = Providers::Registry.registered_types
        if types.empty?
          @output.puts "No provider types available."
          return nil
        end

        @output.puts "Available provider types:"
        types.each_with_index { |t, i| @output.puts "  #{i + 1}) #{t}" }
        @output.print "Select provider to configure (1-#{types.size}): "
        selection = @input.gets&.strip.to_i
        return nil if selection < 1 || selection > types.size

        types[selection - 1]
      end

      def resolve_provider_name(provider_type, cli_options)
        if cli_options.any?
          provider_type
        else
          prompt_provider_name(provider_type)
        end
      end

      def prompt_provider_name(provider_type)
        config = load_or_create_config
        existing = config.fetch("providers", {}).keys
        suggestions = existing.select { |k| k.start_with?(provider_type) }

        suggested = if suggestions.any?
                      "#{provider_type}#{suggestions.size + 1}"
                    else
                      provider_type
                    end

        @output.print "Provider name [#{suggested}]: "
        name = @input.gets&.strip
        name.empty? ? suggested : name
      end

      def build_config_entry(provider_type, fields, cli_options)
        entry = { "type" => provider_type }
        secrets = {}

        fields.each do |field|
          value = cli_options[field.name] || prompt_for_field(field)
          next if value.nil? || value.empty?

          if field.secret
            secrets[field.name] = value
          else
            entry[field.name] = value
          end
        end

        store_secrets(provider_type_from_entry(entry), secrets) if secrets.any?
        entry
      end

      def prompt_for_field(field)
        @output.print "#{field.label}#{" (required)" if field.required}: "
        value = read_input(field)

        if value.nil? || (value.empty? && field.required)
          @output.puts "  #{field.label} is required."
          prompt_for_field(field)
        elsif value.empty?
          nil
        else
          value
        end
      end

      def read_input(field)
        if field.secret && @input.respond_to?(:noecho)
          @input.noecho(&:gets)&.chomp.tap { @output.puts }
        else
          @input.gets&.chomp
        end
      end

      def store_secrets(provider_name, secrets)
        existing = @credential_store.list.include?(provider_name) ? @credential_store.retrieve(provider_name) : {}
        @credential_store.store(provider_name, existing.merge(secrets))
      rescue AuthenticationError
        @credential_store.store(provider_name, secrets)
      end

      def check_existing!(config, provider_name, provider_type, force)
        return unless config.dig("providers", provider_name)

        return if force

        raise ProviderError,
              "Provider '#{provider_name}' (#{provider_type}) is already configured. " \
              "Please use --force to overwrite the existing configuration."
      end

      def handle_download_dir(config_entry, cli_options)
        if cli_options.key?("download_dir")
          config_entry["download_dir"] = cli_options["download_dir"]
        elsif cli_options.empty?
          default = File.join(Dir.home, "Documents", "invoices")
          @output.print "Download directory [#{default}]: "
          dir = @input.gets&.strip.to_s
          config_entry["download_dir"] = dir unless dir.empty?
        end
      end

      def provider_type_from_entry(entry)
        entry["type"]
      end

      def load_or_create_config
        if File.exist?(@config_path)
          Psych.safe_load_file(@config_path, permitted_classes: [Date, Time]) || {}
        else
          { "providers" => {} }
        end
      end

      def save_config(config)
        FileUtils.mkdir_p(File.dirname(@config_path))
        File.write(@config_path, Psych.dump(config))
      end
    end
  end
end
