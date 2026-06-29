# Recurring Document Fetcher

Automate retrieval of invoices and statements from providers (Telekom, utilities, banks).

## Installation

```bash
gem install recurring-document-fetcher
```

## Usage

```bash
recurring-document-fetcher configure                   # Interactive provider setup
recurring-document-fetcher configure handyvertrag      # Configure a specific provider
recurring-document-fetcher configure --list             # List provider types and their fields
recurring-document-fetcher fetch                       # Fetch documents from all providers
recurring-document-fetcher fetch -p handyvertrag       # Fetch from one provider
recurring-document-fetcher status                      # Show download history
recurring-document-fetcher credentials store handyvertrag  # Store credentials manually
recurring-document-fetcher --help                      # Show all commands
```

### Configuration

Each provider type declares the fields it needs via `config_fields`. Non-secret fields (e.g. username) are stored in the YAML config file. Secret fields (e.g. passwords) are encrypted at rest using libsodium via the credential store.

#### Interactive setup (recommended)

```bash
recurring-document-fetcher configure handyvertrag
```

Prompts for each field and stores secrets automatically.

#### Non-interactive setup

Pass field values after `--`:

```bash
recurring-document-fetcher configure handyvertrag -c config.yml -- --username "015712345678" --password "secret123"
```

#### List available providers and their fields

```bash
recurring-document-fetcher configure --list
```

#### Manual setup

```bash
recurring-document-fetcher init              # Generate config template
# Edit ~/.config/recurring-document-fetcher/config.yml
recurring-document-fetcher credentials store handyvertrag  # Store secrets
recurring-document-fetcher fetch
```

### Available providers

| Provider | Type key | Fields |
|---|---|---|
| Handyvertrag.de | `handyvertrag` | `username` (mobile number), `password` [secret] |

### Secrets

Passwords, tokens, and PINs are encrypted at rest using NaCl (libsodium) via `CredentialStore`. They are prompted during `configure` and stored separately from the config file. Set `RECURRING_DOCUMENT_FETCHER_PASSPHRASE` environment variable or provide it when prompted.

```bash
export RECURRING_DOCUMENT_FETCHER_PASSPHRASE="your-secure-passphrase"
recurring-document-fetcher configure handyvertrag
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
