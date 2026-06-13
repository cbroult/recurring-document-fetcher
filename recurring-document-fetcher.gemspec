# frozen_string_literal: true

require_relative "lib/recurring_document_fetcher/version"

Gem::Specification.new do |spec|
  spec.name          = "recurring-document-fetcher"
  spec.version       = RecurringDocumentFetcher::VERSION
  spec.authors       = ["Christophe Broult"]
  spec.email         = ["cbroult@yahoo.com"]
  spec.summary       = "Automate retrieval of invoices from providers (Telekom, utilities, banks)"
  spec.homepage      = "https://github.com/cbroult/recurring-document-fetcher"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb", "bin/*", "data/**/*"]
  spec.bindir        = "bin"
  spec.executables   = ["recurring-document-fetcher"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= #{File.read(File.join(__dir__, ".ruby-version")).strip}"

  spec.add_dependency "faraday"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "ferrum"
  spec.add_dependency "psych-pure"
  spec.add_dependency "rbnacl"
  spec.add_dependency "sqlite3"
  spec.add_dependency "thor"
  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "aruba"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-cucumber"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "webrick"

  spec.metadata["rubygems_mfa_required"] = "true"
end
