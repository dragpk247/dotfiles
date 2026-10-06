#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

echo "==> Installing HexaCore Workstation Layout for Omarchy & Hyprland..."

mkdir -p "$BIN_DIR"
cp "$REPO_DIR/bin/workflow-hexacore" "$BIN_DIR/workflow-hexacore"
chmod +x "$BIN_DIR/workflow-hexacore"
ln -sf "$BIN_DIR/workflow-hexacore" "$BIN_DIR/hexacore"

# Check if keybinding exists in ~/.config/hypr/bindings.lua
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
if [ -f "$BINDINGS_FILE" ]; then
    if ! grep -q "workflow-hexacore" "$BINDINGS_FILE"; then
        echo "==> Adding keybinding (Super + Alt + H) to $BINDINGS_FILE..."
        cat << 'EOF' >> "$BINDINGS_FILE"

-- HexaCore 6-workspace environment trigger
o.bind("SUPER ALT", "H", hl.dsp.exec("workflow-hexacore"))
EOF
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl reload >/dev/null 2>&1 || true
        fi
    else
        echo "==> Keybinding already present in $BINDINGS_FILE."
    fi
fi

echo "==> Installation complete!"
echo "Run 'hexacore' or press Super + Alt + H to deploy your workstation."
