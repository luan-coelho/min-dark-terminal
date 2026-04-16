#!/usr/bin/env bash
# Min Dark Terminal — Uninstaller
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[info]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }

echo ""
echo -e "  ${BLUE}Min Dark Terminal${NC} — Uninstaller"
echo ""

# --------------------------------------------------------------------------- #
# GNOME Terminal
# --------------------------------------------------------------------------- #
if command -v dconf &>/dev/null; then
  info "Looking for Min Dark GNOME Terminal profiles..."

  profile_list=$(dconf read /org/gnome/terminal/legacy/profiles:/list 2>/dev/null || echo "[]")
  found=0

  # Iterate over profiles and find ones named "Min Dark"
  for uuid in $(echo "$profile_list" | tr -d "[]' " | tr ',' '\n'); do
    name=$(dconf read "/org/gnome/terminal/legacy/profiles:/:${uuid}/visible-name" 2>/dev/null || echo "")
    if [[ "$name" == "'Min Dark'" ]]; then
      info "Removing profile ${uuid}..."
      dconf reset -f "/org/gnome/terminal/legacy/profiles:/:${uuid}/"

      # Remove from list
      new_list=$(echo "$profile_list" | sed "s/'${uuid}'//" | sed "s/,\s*,/,/" | sed "s/\[,/[/" | sed "s/,\]/]/")
      dconf write /org/gnome/terminal/legacy/profiles:/list "${new_list}"

      success "Removed GNOME Terminal profile."
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    info "No Min Dark GNOME Terminal profile found."
  fi
else
  info "dconf not found, skipping GNOME Terminal."
fi

# --------------------------------------------------------------------------- #
# Oh My Zsh
# --------------------------------------------------------------------------- #
zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
theme_dir="${zsh_custom}/themes/min-dark"

if [[ -d "$theme_dir" ]]; then
  rm -rf "$theme_dir"
  success "Removed Oh My Zsh theme from ${theme_dir}"

  zshrc="${HOME}/.zshrc"
  if grep -q 'ZSH_THEME="min-dark/min-dark"' "$zshrc" 2>/dev/null; then
    sed -i 's|ZSH_THEME="min-dark/min-dark"|ZSH_THEME="robbyrussell"|' "$zshrc"
    warn "Reset ZSH_THEME to robbyrussell in .zshrc. Change it to your preferred theme."
  fi
else
  info "No Oh My Zsh theme found."
fi

echo ""
info "Restart your terminal to apply changes."
