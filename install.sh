#!/bin/bash
# ==============================================================================
# Matugen Dynamic Theme Installer for Omarchy Linux
# https://github.com/m7sh/matugen-theme
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$HOME/.config/omarchy/themes/matugen"
MATUGEN_DIR="$HOME/.config/matugen"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
HOOKS_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
HYPR_AUTOSTART="$HOME/.config/hypr/autostart.lua"

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
NC="\033[0m"

log_info() { echo -e "${BLUE}::${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}!${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Handle uninstallation
if [[ "${1:-}" == "--uninstall" ]]; then
  echo -e "\n${BOLD}=== Uninstalling Matugen Dynamic Theme ===${NC}\n"

  # Stop and disable service
  if systemctl --user is-active --quiet matugen-watch.service 2>/dev/null; then
    systemctl --user stop matugen-watch.service || true
    systemctl --user disable matugen-watch.service || true
    log_success "Stopped and disabled matugen-watch.service"
  fi
  rm -f "$SYSTEMD_USER_DIR/matugen-watch.service"
  systemctl --user daemon-reload 2>/dev/null || true

  # Remove hooks and scripts
  rm -f "$HOOKS_DIR/matugen.hook"
  rm -f "$BIN_DIR/matugen-omarchy" "$BIN_DIR/matugen-watch" "$BIN_DIR/matugen-sync"
  log_success "Removed helper scripts and hooks"

  # Remove theme directory
  if [[ -d "$THEME_DIR" || -L "$THEME_DIR" ]]; then
    rm -rf "$THEME_DIR"
    log_success "Removed theme at $THEME_DIR"
  fi

  # Clean autostart.lua
  if [[ -f "$HYPR_AUTOSTART" ]]; then
    sed -i '/matugen-watch/d' "$HYPR_AUTOSTART"
    log_success "Removed autostart entry from $HYPR_AUTOSTART"
  fi

  echo -e "\n${GREEN}Uninstallation complete!${NC}\n"
  exit 0
fi

echo -e "\n${BOLD}=== Installing Matugen Dynamic Theme for Omarchy ===${NC}\n"

# 1. Ensure ~/.local/bin is created and on PATH
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# 2. Check / Install Matugen binary
log_info "Checking Matugen binary..."
if ! command -v matugen &>/dev/null; then
  log_info "Matugen not found. Installing prebuilt binary..."
  ARCH=$(uname -m)
  if [[ "$ARCH" == "x86_64" ]]; then
    MATUGEN_URL="https://github.com/InioX/matugen/releases/latest/download/matugen-4.2.0-x86_64.tar.gz"
    if curl -sL "$MATUGEN_URL" | tar -xz -C "$BIN_DIR" 2>/dev/null; then
      chmod +x "$BIN_DIR/matugen"
      log_success "Installed Matugen binary to $BIN_DIR/matugen"
    else
      log_warn "Failed to download prebuilt tarball. Attempting package manager..."
      if command -v pacman &>/dev/null && (( EUID == 0 || $(sudo -n true 2>/dev/null; echo $?) == 0 )); then
        sudo pacman -S --noconfirm --needed matugen || true
      fi
    fi
  fi
fi

if command -v matugen &>/dev/null; then
  log_success "Matugen ready: $(matugen --version)"
else
  log_error "Matugen could not be installed automatically."
  echo "  Please install it manually via: sudo pacman -S matugen  OR  cargo install matugen"
  exit 1
fi

# 3. Check for inotifywait (required for real-time wallpaper watching)
log_info "Checking inotify-tools..."
if ! command -v inotifywait &>/dev/null; then
  if command -v pacman &>/dev/null && (( EUID == 0 || $(sudo -n true 2>/dev/null; echo $?) == 0 )); then
    sudo pacman -S --noconfirm --needed inotify-tools
  else
    log_warn "'inotifywait' is not installed. Real-time wallpaper watching requires 'inotify-tools'."
    echo "  Install via: sudo pacman -S inotify-tools"
  fi
else
  log_success "inotifywait ready"
fi

# 4. Install theme files into ~/.config/omarchy/themes/matugen
log_info "Installing theme files..."
mkdir -p "$HOME/.config/omarchy/themes"

# If THEME_DIR exists and is a directory (not this script dir)
if [[ -d "$THEME_DIR" && "$THEME_DIR" != "$SCRIPT_DIR" ]]; then
  rm -rf "$THEME_DIR"
fi
mkdir -p "$THEME_DIR/backgrounds"

# Copy wallpapers and theme metadata
cp -r "$SCRIPT_DIR/backgrounds/"* "$THEME_DIR/backgrounds/"
for file in icons.theme preview.png unlock.png hyprlock.conf cava_theme colors.toml hyprland.lua shell.toml; do
  if [[ -f "$SCRIPT_DIR/$file" ]]; then
    cp "$SCRIPT_DIR/$file" "$THEME_DIR/"
  fi
done
log_success "Theme installed to $THEME_DIR (with 7 curated 4K wallpapers)"

# 5. Install Matugen configuration and templates
log_info "Installing Matugen configuration and templates..."
mkdir -p "$MATUGEN_DIR/templates"
cp "$SCRIPT_DIR/matugen/config.toml" "$MATUGEN_DIR/"
cp -r "$SCRIPT_DIR/matugen/templates/"* "$MATUGEN_DIR/templates/"
log_success "Templates installed to $MATUGEN_DIR"

# 6. Install helper scripts
log_info "Installing helper scripts to $BIN_DIR..."
cp "$SCRIPT_DIR/scripts/matugen-omarchy" "$BIN_DIR/"
cp "$SCRIPT_DIR/scripts/matugen-watch" "$BIN_DIR/"
cp "$SCRIPT_DIR/scripts/matugen-sync" "$BIN_DIR/"
chmod +x "$BIN_DIR/matugen-omarchy" "$BIN_DIR/matugen-watch" "$BIN_DIR/matugen-sync"
log_success "Helper scripts installed (matugen-omarchy, matugen-watch, matugen-sync)"

# 7. Install theme-set hook
log_info "Installing Omarchy theme-set hook..."
mkdir -p "$HOOKS_DIR"
if [[ -f "$SCRIPT_DIR/hooks/matugen.hook" ]]; then
  cp "$SCRIPT_DIR/hooks/matugen.hook" "$HOOKS_DIR/"
else
  cat <<'EOF' > "$HOOKS_DIR/matugen.hook"
#!/bin/bash
set -euo pipefail
[[ ${OMARCHY_THEME_SKIP_BACKGROUND:-} == "1" ]] && exit 0
[[ "${1:-}" == "matugen" ]] || exit 0
export PATH="$HOME/.local/bin:$PATH"
if ! pgrep -f "matugen-watch" >/dev/null 2>&1; then
  nohup "$HOME/.local/bin/matugen-watch" >/dev/null 2>&1 &
fi
"$HOME/.local/bin/matugen-omarchy" || true
EOF
fi
chmod +x "$HOOKS_DIR/matugen.hook"
log_success "Hook installed to $HOOKS_DIR/matugen.hook"

# 8. Setup systemd user service
log_info "Setting up systemd user service..."
mkdir -p "$SYSTEMD_USER_DIR"
if [[ -f "$SCRIPT_DIR/systemd/matugen-watch.service" ]]; then
  cp "$SCRIPT_DIR/systemd/matugen-watch.service" "$SYSTEMD_USER_DIR/"
else
  cat <<'EOF' > "$SYSTEMD_USER_DIR/matugen-watch.service"
[Unit]
Description=Matugen dynamic wallpaper watcher for Omarchy
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/matugen-watch
Restart=always
RestartSec=3
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin
Environment=XDG_RUNTIME_DIR=%t

[Install]
WantedBy=graphical-session.target
EOF
fi

if command -v systemctl &>/dev/null; then
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable --now matugen-watch.service 2>/dev/null || true
  log_success "Systemd user service enabled & started (matugen-watch.service)"
fi

# 9. Register in Hyprland autostart
if [[ -f "$HYPR_AUTOSTART" ]]; then
  if ! grep -q "matugen-watch" "$HYPR_AUTOSTART"; then
    log_info "Adding watcher to $HYPR_AUTOSTART..."
    echo 'o.launch_on_start(os.getenv("HOME") .. "/.local/bin/matugen-watch")' >> "$HYPR_AUTOSTART"
    log_success "Added autostart entry to $HYPR_AUTOSTART"
  fi
fi

# 10. Apply theme now
if command -v omarchy &>/dev/null; then
  log_info "Applying Matugen theme via Omarchy..."
  omarchy theme set matugen >/dev/null 2>&1 || true
  log_success "Theme activated: $(omarchy theme current 2>/dev/null || echo 'Matugen')"
fi

echo -e "\n${GREEN}${BOLD}✓ Installation finished successfully!${NC}"
echo -e "Cycle wallpapers anytime:   ${BLUE}omarchy theme bg next${NC}"
echo -e "Force regeneration:         ${BLUE}matugen-omarchy${NC}"
echo -e "Check background watcher:   ${BLUE}systemctl --user status matugen-watch.service${NC}\n"
