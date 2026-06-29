# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Commands::Configure do
  subject(:command) do
    described_class.new(
      config_path: config_path,
      credential_store: credential_store,
      output: output,
      input: input
    )
  end

  let(:config_path) { File.join(Dir.tmpdir, "rdf_configure_test_#{Process.pid}.yml") }
  let(:credential_store) { instance_double(RecurringDocumentFetcher::CredentialStore) }
  let(:output) { StringIO.new }
  let(:input) { StringIO.new }
  let(:test_provider_class) do
    Class.new(RecurringDocumentFetcher::Providers::Base) do
      def self.config_fields
        [
          RecurringDocumentFetcher::ConfigField.new(name: "username", label: "Username", required: true,
                                                    secret: false),
          RecurringDocumentFetcher::ConfigField.new(name: "password", label: "Password", required: true,
                                                    secret: true)
        ]
      end

      def self.name
        "TestProvider"
      end
    end
  end

  around do |example|
    saved = RecurringDocumentFetcher::Providers::Registry.send(:registry).dup
    RecurringDocumentFetcher::Providers::Registry.clear
    example.run
    RecurringDocumentFetcher::Providers::Registry.send(:registry).replace(saved)
  end

  after do
    FileUtils.rm_f(config_path)
  end

  before do
    RecurringDocumentFetcher::Providers::Registry.register("test_provider", test_provider_class)
  end

  describe "#list" do
    it "prints provider types and their fields" do
      command.list

      expect(output.string).to include("test_provider")
      expect(output.string).to include("--username: Username (required)")
      expect(output.string).to include("--password: Password (required) [secret]")
    end
  end

  describe "#call" do
    context "with non-interactive cli_options" do
      it "writes non-secret fields to config and secrets to credential store" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret123" })

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_provider"]["type"]).to eq("test_provider")
        expect(config["providers"]["test_provider"]["username"]).to eq("john")
        expect(config["providers"]["test_provider"]).not_to have_key("password")
      end

      it "stores secrets in credential store" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret123" })

        expect(credential_store).to have_received(:store).with("test_provider", { "password" => "secret123" })
      end

      it "preserves existing config entries" do
        File.write(config_path, <<~YAML)
          download_dir: /custom/path
          providers:
            existing:
              type: other
        YAML

        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret123" })

        config = Psych.safe_load_file(config_path)
        expect(config["download_dir"]).to eq("/custom/path")
        expect(config["providers"]).to have_key("existing")
        expect(config["providers"]).to have_key("test_provider")
      end

      it "merges secrets with existing credential store data" do
        allow(credential_store).to receive(:list).and_return(["test_provider"])
        allow(credential_store).to receive(:retrieve).with("test_provider").and_return("api_key" => "abc")
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret123" })

        expect(credential_store).to have_received(:store).with("test_provider",
                                                               { "api_key" => "abc", "password" => "secret123" })
      end

      it "stores download_dir when provided" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider",
                     cli_options: { "username" => "john", "password" => "secret123", "download_dir" => "/custom/path" })

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_provider"]["download_dir"]).to eq("/custom/path")
      end

      it "does not store download_dir when not provided in non-interactive mode" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret123" })

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_provider"]).not_to have_key("download_dir")
      end
    end

    context "when provider is already configured" do
      before do
        File.write(config_path, <<~YAML)
          providers:
            test_provider:
              type: test_provider
              username: old_user
        YAML
      end

      it "refuses without --force" do
        expect do
          command.call("test_provider", cli_options: { "username" => "new_user", "password" => "secret" })
        end.to raise_error(RecurringDocumentFetcher::ProviderError,
                           /already configured.*--force/)
      end

      it "overwrites with --force" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "new_user", "password" => "secret" }, force: true)

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_provider"]["username"]).to eq("new_user")
      end

      it "preserves unrelated providers with --force" do
        File.write(config_path, <<~YAML)
          providers:
            test_provider:
              type: test_provider
              username: old_user
            other:
              type: other
        YAML

        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "new_user", "password" => "secret" }, force: true)

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_provider"]["username"]).to eq("new_user")
        expect(config["providers"]["other"]["type"]).to eq("other")
      end
    end

    context "with interactive input" do
      def run_interactive(input_lines)
        input.string = "#{input_lines.join("\n")}\n"
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)
        yield
      end

      it "prompts for missing required fields" do
        run_interactive(%w[test_name john secret123]) do
          command.call("test_provider", cli_options: {})
        end

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_name"]["username"]).to eq("john")
      end

      it "includes the success message" do
        run_interactive(%w[test_name john secret123]) do
          command.call("test_provider", cli_options: {})
        end

        expect(output.string).to include("Configured")
      end

      it "re-prompts when required field is empty" do
        input.string = "test_name\n\njohn\nsecret123\n"
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: {})

        expect(output.string).to include("is required")
      end

      it "does not prompt for provider name when cli_options given" do
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call("test_provider", cli_options: { "username" => "john", "password" => "secret" })

        expect(output.string).not_to include("Provider name")
      end
    end

    context "without provider type" do
      it "shows interactive menu" do
        input.string = "1\ntest_name\njohn\nsecret123\n"
        allow(credential_store).to receive(:list).and_return([])
        allow(credential_store).to receive(:store)

        command.call(nil, cli_options: {})

        expect(output.string).to include("Available provider types")
        expect(output.string).to include("test_provider")

        config = Psych.safe_load_file(config_path)
        expect(config["providers"]["test_name"]["username"]).to eq("john")
      end
    end

    context "with unknown provider type" do
      it "raises ProviderError" do
        expect { command.call("unknown") }
          .to raise_error(RecurringDocumentFetcher::ProviderError, /Unknown provider type: unknown/)
      end
    end
  end
end
