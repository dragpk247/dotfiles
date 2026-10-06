#!/usr/bin/env bash
# Root install script for dotfiles
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/bin/omarchy-dotfiles" install "$@"
