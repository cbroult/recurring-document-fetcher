# Recurring Document Fetcher

Automate retrieval of invoices and statements from providers (Telekom, utilities, banks).

## Installation

```bash
gem install recurring-document-fetcher
```

## Usage

```bash
recurring-document-fetcher init          # Generate config template
recurring-document-fetcher fetch         # Fetch documents from all providers
recurring-document-fetcher fetch -p telekom  # Fetch from one provider
recurring-document-fetcher status        # Show download history
recurring-document-fetcher --help        # Show all commands
```

## Development

```bash
bundle install
bundle exec rake          # Run all checks (spec, cucumber, rubocop, bundler-audit)
bundle exec rake spec     # Unit tests only
bundle exec rake features # Acceptance tests only
```

## License

MIT
