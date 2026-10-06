#!/usr/bin/env bash
# Root sync script for dotfiles
set -euo pipefail
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
exec "$DIR/bin/omarchy-dotfiles" sync "$@"
