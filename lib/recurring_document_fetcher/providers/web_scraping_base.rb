# frozen_string_literal: true

require "ferrum"

module RecurringDocumentFetcher
  module Providers
    class WebScrapingBase < Base
      def initialize(config:, credential_store:, browser_factory: method(:default_browser_factory))
        super(config:, credential_store:)
        @browser_factory = browser_factory
        @browser = nil
      end

      def disconnect
        @browser&.quit
        @browser = nil
      end

      private

      def browser
        @browser ||= @browser_factory.call(headless: config.fetch("headless", true))
      end

      def page
        browser.page
      end

      def navigate_to(url)
        with_rate_limit { page.go_to(url) }
      end

      def wait_for_selector(selector, timeout: 10)
        page.at_css(selector, wait: timeout)
      end

      def fill_field(selector, value)
        node = wait_for_selector(selector)
        node.focus.type(value)
      end

      def click(selector)
        node = wait_for_selector(selector)
        node.click
      end

      def page_text
        page.body_text
      end

      def page_html
        page.body
      end

      def screenshot(path)
        page.screenshot(path:)
      end

      def dismiss_cookie_consent(selectors: [])
        default_selectors = [
          "[data-testid='cookie-accept']",
          "#accept-cookies",
          ".cookie-consent-accept",
          "button[id*='cookie']"
        ]

        (selectors + default_selectors).each do |selector|
          node = page.at_css(selector)
          if node
            node.click
            break
          end
        rescue Ferrum::NodeNotFoundError
          next
        end
      end

      def self.default_browser_factory(headless: true)
        Ferrum::Browser.new(headless:, timeout: 30, window_size: [1280, 800])
      end
      private_class_method :default_browser_factory
    end
  end
end
