#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$HOME/.config/omarchy/themes/matugen"
MATUGEN_DIR="$HOME/.config/matugen"
BIN_DIR="$HOME/.local/bin"

echo "=== Installing Matugen Theme for Omarchy ==="

# 1. Install / link theme to omarchy themes
mkdir -p "$HOME/.config/omarchy/themes"
if [[ -d "$THEME_DIR" && ! -L "$THEME_DIR" ]]; then
  echo "Backing up existing theme at $THEME_DIR..."
  mv "$THEME_DIR" "${THEME_DIR}.bak.$(date +%s)"
fi
ln -sfn "$SCRIPT_DIR" "$THEME_DIR"
echo "✓ Theme linked to $THEME_DIR"

# 2. Install matugen configuration and templates
mkdir -p "$MATUGEN_DIR"
cp -r "$SCRIPT_DIR/matugen/"* "$MATUGEN_DIR/"
echo "✓ Matugen templates installed to $MATUGEN_DIR"

# 3. Install watcher scripts
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/scripts/"* "$BIN_DIR/"
chmod +x "$BIN_DIR/matugen-omarchy" "$BIN_DIR/matugen-watch" "$BIN_DIR/matugen-sync"
echo "✓ Helper scripts installed to $BIN_DIR"

# 4. Check for matugen binary
if ! command -v matugen &>/dev/null; then
  echo ""
  echo "NOTE: 'matugen' binary not found in PATH."
  echo "      Install it via: cargo install matugen  OR  yay -S matugen-bin"
fi

# 5. Check for inotifywait binary
if ! command -v inotifywait &>/dev/null; then
  echo ""
  echo "NOTE: 'inotifywait' not found. Install inotify-tools via: sudo pacman -S inotify-tools"
fi

echo ""
echo "Installation complete!"
echo "Apply theme with:      omarchy theme set matugen"
echo "Start dynamic watcher: ~/.local/bin/matugen-watch &"
