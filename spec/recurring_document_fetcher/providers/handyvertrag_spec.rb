# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::Providers::Handyvertrag do
  describe ".config_fields" do
    subject(:fields) { described_class.config_fields }

    it "returns username and password fields" do
      expect(fields.map(&:name)).to contain_exactly("username", "password")
    end

    it "marks password as secret" do
      password_field = fields.find { |f| f.name == "password" }
      expect(password_field.secret).to be true
    end

    it "marks username as not secret" do
      username_field = fields.find { |f| f.name == "username" }
      expect(username_field.secret).to be false
    end

    it "marks all fields as required" do
      expect(fields).to all(have_attributes(required: true))
    end
  end

  describe "#authenticate", :browser do
    subject(:provider) do
      described_class.new(
        config: config,
        credential_store: credential_store,
        browser_factory: browser_factory
      )
    end

    let(:config) { { "headless" => true, "rate_limit_seconds" => 0, "username" => "015712345678" } }
    let(:credential_store) { instance_double(RecurringDocumentFetcher::CredentialStore) }
    let(:browser) { instance_double(Ferrum::Browser, page: page) }
    let(:page) { instance_double(Ferrum::Page) }
    let(:browser_factory) { ->(**_opts) { browser } }

    before do
      allow(credential_store).to receive(:retrieve).with("handyvertrag").and_return(
        "password" => "secret"
      )
    end

    describe "registration" do
      it "is registered as 'handyvertrag'" do
        expect(RecurringDocumentFetcher::Providers::Registry.resolve("handyvertrag")).to eq(described_class)
      end
    end

    describe "#authenticate" do
      let(:username_node) { instance_double(Ferrum::Node) }
      let(:password_node) { instance_double(Ferrum::Node) }
      let(:logout_node) { instance_double(Ferrum::Node) }
      let(:keyboard) { instance_double(Ferrum::Keyboard) }

      before do
        allow(page).to receive(:go_to)
        allow(page).to receive(:at_css).with("#UserLoginType_alias", wait: 10).and_return(username_node)
        allow(page).to receive(:at_css).with("#UserLoginType_password", wait: 10).and_return(password_node)
        allow(page).to receive(:at_css).with("#UserLoginType_password").and_return(password_node)
        allow(page).to receive(:keyboard).and_return(keyboard)
        allow(keyboard).to receive(:type)
        allow(username_node).to receive(:focus).and_return(username_node)
        allow(username_node).to receive(:type)
        allow(password_node).to receive(:focus).and_return(password_node)
        allow(password_node).to receive(:type)

        # Login result
        allow(page).to receive(:at_css)
          .with("img[alt*='LOGOUT'], [data-test-id='unified-login-error']", wait: 15)
          .and_return(logout_node)
        allow(page).to receive(:at_css).with("[data-test-id='unified-login-error']").and_return(nil)
        allow(page).to receive(:at_css).with("img[alt*='LOGOUT']").and_return(logout_node)

        # Cookie consent
        allow(page).to receive(:at_css).with("#consent_wall_optin", wait: 10).and_return(nil)
        allow(page).to receive(:at_css).with(anything).and_return(nil)
      end

      it "logs in with credentials from the store" do
        provider.authenticate

        expect(username_node).to have_received(:type).with("015712345678")
        expect(password_node).to have_received(:type).with("secret")
      end

      context "when login fails" do # rubocop:disable RSpec/NestedGroups
        let(:error_node) { instance_double(Ferrum::Node) }

        before do
          allow(page).to receive(:at_css)
            .with("[data-test-id='unified-login-error']")
            .and_return(error_node)
          allow(page).to receive(:at_css)
            .with("img[alt*='LOGOUT']")
            .and_return(nil)
        end

        it "raises AuthenticationError" do
          expect { provider.authenticate }
            .to raise_error(RecurringDocumentFetcher::AuthenticationError, /login failed/)
        end
      end
    end

    describe "#list_documents" do
      let(:button1) { instance_double(Ferrum::Node, text: "Rechnung Januar 2026") }
      let(:parent_element) { instance_double(Ferrum::Node) }
      let(:invoice_link) { instance_double(Ferrum::Node) }

      before do
        allow(page).to receive(:go_to)
        allow(page).to receive(:css).with("[id^='heading-rechnungen-'] button").and_return([button1])
        allow(button1).to receive(:click)

        allow(button1).to receive(:evaluate)
          .with("this.closest('[id^=\"heading-rechnungen-\"]').parentElement")
          .and_return(parent_element)

        # Invoice link
        allow(parent_element).to receive(:evaluate)
          .with(anything, "Rechnung")
          .and_return([invoice_link])
        allow(invoice_link).to receive(:property)
          .with("href")
          .and_return("https://service.handyvertrag.de/mytariff/invoice/download/12345")

        # No EVN links
        allow(parent_element).to receive(:evaluate)
          .with(anything, "Einzelverbindungsnachweis")
          .and_return([])
      end

      it "returns documents found in expanded sections" do
        documents = provider.list_documents

        expect(documents.size).to eq(1)
        expect(documents.first.id).to eq("12345")
        expect(documents.first.category).to eq("invoice")
        expect(documents.first.provider).to eq("handyvertrag")
        expect(documents.first.date).to eq(Date.new(2026, 1, 1))
      end
    end

    describe "#download" do
      let(:document) do
        RecurringDocumentFetcher::Document.new(
          id: "12345", provider: "handyvertrag", date: Date.new(2026, 1, 1),
          category: "invoice", filename: "test.pdf",
          url: "https://service.handyvertrag.de/mytariff/invoice/download/12345"
        )
      end

      it "downloads document content to destination" do
        allow(page).to receive(:go_to)
        allow(page).to receive(:body).and_return("%PDF-1.4 test content")

        dest = File.join(Dir.tmpdir, "rdf_handyvertrag_test_#{Process.pid}.pdf")
        provider.download(document, destination: dest)

        expect(File.read(dest)).to eq("%PDF-1.4 test content")
      ensure
        FileUtils.rm_f(dest) if dest
      end
    end

    describe "#disconnect" do
      it "quits the browser" do
        provider.send(:browser)
        expect(browser).to receive(:quit)
        provider.disconnect
      end
    end
  end
end
