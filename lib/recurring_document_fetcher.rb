# frozen_string_literal: true

require "thor"
require "psych/pure"
require "zeitwerk"

module RecurringDocumentFetcher
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class ProviderError < Error; end
  class DownloadError < Error; end
  class ValidationError < Error; end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("cli" => "CLI")
loader.setup
loader.eager_load
