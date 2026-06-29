# frozen_string_literal: true

module RecurringDocumentFetcher
  module Providers
    class Handyvertrag < WebScrapingBase
      URL_LOGIN = "https://service.handyvertrag.de/"
      URL_LOGOUT = "https://service.handyvertrag.de/public/prelogout"
      URL_INVOICES = "https://service.handyvertrag.de/mytariff/invoice/showAll"

      USERNAME_SELECTOR = "#UserLoginType_alias"
      PASSWORD_SELECTOR = "#UserLoginType_password"
      COOKIE_CONSENT_SELECTOR = "#consent_wall_optin"
      LOGOUT_INDICATOR = "img[alt*='LOGOUT']"
      LOGIN_ERROR_SELECTOR = "[data-test-id='unified-login-error']"
      INVOICE_HEADING_SELECTOR = "[id^='heading-rechnungen-'] button"

      GERMAN_MONTHS = {
        "Januar" => 1, "Februar" => 2, "März" => 3, "April" => 4,
        "Mai" => 5, "Juni" => 6, "Juli" => 7, "August" => 8,
        "September" => 9, "Oktober" => 10, "November" => 11, "Dezember" => 12
      }.freeze

      Registry.register("handyvertrag", self)

      def self.config_fields
        [
          ConfigField.new(name: "username", label: "Mobile number", required: true, secret: false),
          ConfigField.new(name: "password", label: "Password", required: true, secret: true)
        ]
      end

      def authenticate
        secret = credential_store.retrieve(provider_name)
        navigate_to(URL_LOGIN)

        fill_field(USERNAME_SELECTOR, config.fetch("username"))
        fill_field(PASSWORD_SELECTOR, secret.fetch("password"))

        page.at_css(PASSWORD_SELECTOR).focus
        page.keyboard.type(:Enter)

        wait_for_login_result
        dismiss_cookie_consent(selectors: [COOKIE_CONSENT_SELECTOR])
      end

      def list_documents
        navigate_to(URL_INVOICES)
        documents = []

        expand_invoice_sections.each do |section|
          documents.concat(extract_documents_from_section(section))
        end

        documents
      end

      def download(document, destination:)
        with_rate_limit do
          page.go_to(document.url)
          content = page.body
          File.binwrite(destination, content)
        end
      end

      private

      def wait_for_login_result
        page.at_css("#{LOGOUT_INDICATOR}, #{LOGIN_ERROR_SELECTOR}", wait: 15)

        if page.at_css(LOGIN_ERROR_SELECTOR)
          raise AuthenticationError, "Handyvertrag login failed. Check your credentials."
        end

        return if page.at_css(LOGOUT_INDICATOR)

        raise AuthenticationError, "Handyvertrag login failed. Unexpected page state."
      end

      def expand_invoice_sections
        buttons = page.css(INVOICE_HEADING_SELECTOR)
        buttons.each do |button|
          with_rate_limit { button.click }
          sleep 0.3 # allow collapsible section to expand
        end
        buttons
      end

      def extract_documents_from_section(section)
        documents = []
        description = section.text.strip
        date = parse_german_date(description)
        parent = section.evaluate("this.closest('[id^=\"heading-rechnungen-\"]').parentElement")

        # Invoice PDF
        invoice_links = find_links_in_element(parent, "Rechnung")
        invoice_links.each do |link|
          url = link.property("href")
          doc_id = url.split("/").last
          documents << build_document(doc_id, date, "invoice", url, description)
        end

        # Call detail record
        evn_links = find_links_in_element(parent, "Einzelverbindungsnachweis")
        evn_links.each do |link|
          url = link.property("href")
          doc_id = url.split("/").last
          documents << build_document(doc_id, date, "call_log", url, description)
        end

        documents
      end

      def find_links_in_element(element, link_text)
        element.evaluate(
          "function(text) { return Array.from(this.querySelectorAll('a'))" \
          ".filter(a => a.textContent.trim() === text); }",
          link_text
        )
      rescue Ferrum::JavaScriptError
        []
      end

      def build_document(doc_id, date, category, url, description)
        filename = "#{date}_handyvertrag_#{doc_id}.pdf"
        Document.new(
          id: doc_id, provider: "handyvertrag", date: Date.parse(date.to_s),
          category: category, filename: filename, url: url,
          metadata: { description: description }
        )
      end

      def parse_german_date(text)
        # Matches patterns like "Januar 2026" or "15. Januar 2026"
        GERMAN_MONTHS.each do |month_name, month_num|
          next unless text.include?(month_name)

          year = text[/\d{4}/]
          day = text[/(\d{1,2})\.\s*#{month_name}/, 1] || "1"
          return Date.new(year.to_i, month_num, day.to_i)
        end
        Date.today
      end
    end
  end
end
