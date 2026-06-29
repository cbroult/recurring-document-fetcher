# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby CLI gem that automates retrieval of invoices and statements from providers (Telekom, utilities, banks) so users can collect documents locally without manual downloads. Follows convention over configuration.

## Build / Test Commands

```bash
bundle exec rake verify          # Run everything: spec → cucumber → rubocop → bundler-audit
bundle exec rake spec             # Unit tests only
bundle exec rake features         # Acceptance tests only (Cucumber)
bundle exec rspec spec/recurring_document_fetcher/cli_spec.rb  # Single spec file
bundle exec cucumber features/help.feature                      # Single feature file
bundle exec rubocop -A            # Linter with auto-correct
bundle exec rake lint             # Static analysis only (rubocop + bundler-audit)
bundle exec recurring-document-fetcher --help  # Run CLI directly
```

## Architecture

```
RecurringDocumentFetcher (namespace module, VERSION, Error subclasses)
  ├── CLI < Thor              — command routing, global options, error handling
  ├── Configuration           — YAML loading from ~/.config/recurring-document-fetcher/config.yml
  ├── DownloadTracker         — SQLite-backed download log
  ├── DocumentValidator       — post-download file integrity checks
  ├── CredentialStore         — secure credential storage
  ├── Scheduler               — cron entry generation for monthly runs
  ├── Providers::
  │     ├── Base              — abstract: authenticate, list_documents, download
  │     ├── Telekom           — Telekom Kundencenter adapter
  │     ├── Utility           — utility provider adapter
  │     ├── BankStatement     — bank statement adapter
  │     └── Registry          — maps type strings → adapter classes
  └── Commands::
        ├── Fetch             — orchestrate: config → auth → list → download → validate → track
        ├── Init              — generate config template
        ├── Status            — show download history
        ├── Redownload        — force re-fetch
        ├── Schedule          — install/remove/show cron schedule
        └── Credentials       — store/list/delete credentials
```

**Entry point**: `bin/recurring-document-fetcher` → `RecurringDocumentFetcher::CLI.start(ARGV)`

## Development Workflow (BDD + TDD)

1. **BDD outer loop**: Write/update Cucumber scenario first (desired behavior)
2. **TDD inner loop**: Write RSpec unit test, then implement (red-green-refactor)
3. Run `bundle exec rake verify` before considering work done

## Testing Strategy

- **Unit (RSpec + WebMock)**: Mock HTTP at request/response level. Test each class in isolation. Fixtures in `spec/fixtures/`.
- **Acceptance (Cucumber + Aruba)**: Full CLI subprocess testing. Use `RECURRING_DOCUMENT_FETCHER_MOCK_HTTP` env var for HTTP mocking in subprocesses.
- **Contract/live (`@live` tag)**: Manual-only tests against real provider portals. Never run in CI. Excluded by default in cucumber.yml.

## Key Conventions

- Use `should contain exactly:` with full DocString in feature files for file content assertions (documents expected YAML output); never use `should contain` / `should not contain` for file content
- Use `should contain` / `should not contain` only for stdout/stderr output assertions
- Double quotes for strings; `# frozen_string_literal: true` at top of every file
- Named constants (`SCREAMING_SNAKE_CASE`) instead of magic literals
- All exceptions translated to `RecurringDocumentFetcher::Error` subclasses
- Conventional Commits: `type(scope): subject` (present tense, under 50 chars, signed)
- Imports: top-level `require` in `lib/recurring_document_fetcher.rb`, `require_relative` within subdirectories
- Zeitwerk autoloader with `loader.inflector.inflect("cli" => "CLI")`

## Convention over Configuration Defaults

- Config: `~/.config/recurring-document-fetcher/config.yml`
- Downloads: `~/Documents/invoices/<provider_name>/YYYY/`
- File naming: `YYYY-MM-DD_<provider>_<document_id>.<ext>`
- Database: `~/.config/recurring-document-fetcher/downloads.db`

## Configuration Pattern

Every provider class MUST declare its configuration schema via `self.config_fields`:

```ruby
def self.config_fields
  [
    ConfigField.new(name: "username", label: "Mobile number", required: true, secret: false),
    ConfigField.new(name: "password", label: "Password", required: true, secret: true)
  ]
end
```

**Rules:**
- `secret: true` fields are stored in `CredentialStore` (encrypted at rest), never in the YAML config
- `secret: false` fields are stored in the YAML config file
- All fields use `ConfigField` struct (in `config_field.rb`)
- `type`, `required`, `secret`, and `cli_flag` have sensible defaults
- The `configure` CLI command is the single entry point for setup (interactive or `--key value` flags)
- Adding a new provider: implement `config_fields` + register via `Registry.register` + write Cucumber feature + RSpec spec

## Environment Notes

- Ruby >= 4.0 (CI tests on 3.4 and 4.0)
- In Ruby 4.0, `logger`, `rake` are gem dependencies (removed from stdlib)
- RuboCop configured in `.rubocop.yml` with relaxed metrics for CLI methods
