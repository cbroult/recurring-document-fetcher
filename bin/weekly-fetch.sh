#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
bundle exec recurring-document-fetcher fetch
