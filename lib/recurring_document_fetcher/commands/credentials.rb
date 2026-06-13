# frozen_string_literal: true

module RecurringDocumentFetcher
  module Commands
    class Credentials
      def initialize(credential_store:, output: $stdout, input: $stdin)
        @credential_store = credential_store
        @output = output
        @input = input
      end

      def store(provider_name)
        @output.print "Username: "
        username = @input.gets&.chomp
        @output.print "Password: "
        password = @input.gets&.chomp

        @credential_store.store(provider_name, { "username" => username, "password" => password })
        @output.puts "Credentials stored for #{provider_name}."
      end

      def list
        providers = @credential_store.list
        if providers.empty?
          @output.puts "No credentials stored."
        else
          @output.puts "Stored credentials:"
          providers.each { |p| @output.puts "  #{p}" }
        end
      end

      def delete(provider_name)
        @credential_store.delete(provider_name)
        @output.puts "Credentials deleted for #{provider_name}."
      end
    end
  end
end
