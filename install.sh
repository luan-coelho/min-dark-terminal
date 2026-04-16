#!/usr/bin/env bash
# Min Dark Terminal — Installer
# Port of Min Theme by Miguel Solorio (https://github.com/miguelsolorio/min-theme)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[info]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; }

# --------------------------------------------------------------------------- #
# GNOME Terminal
# --------------------------------------------------------------------------- #
install_gnome_terminal() {
  if ! command -v dconf &>/dev/null; then
    warn "dconf not found. Skipping GNOME Terminal install."
    warn "Install it with: sudo apt install dconf-cli"
    return 1
  fi

  if ! command -v uuidgen &>/dev/null; then
    warn "uuidgen not found. Skipping GNOME Terminal install."
    warn "Install it with: sudo apt install uuid-runtime"
    return 1
  fi

  info "Installing GNOME Terminal profile..."

  local profile_slug
  profile_slug=$(uuidgen)
  local dconf_path="/org/gnome/terminal/legacy/profiles:/:${profile_slug}/"

  # Load the dconf profile
  dconf load "${dconf_path}" < "${SCRIPT_DIR}/gnome-terminal/min-dark.dconf"

  # Register in profile list
  local current_list
  current_list=$(dconf read /org/gnome/terminal/legacy/profiles:/list 2>/dev/null || echo "[]")

  if [[ "$current_list" == "[]" || -z "$current_list" ]]; then
    dconf write /org/gnome/terminal/legacy/profiles:/list "['${profile_slug}']"
  else
    local new_list="${current_list%]}, '${profile_slug}']"
    dconf write /org/gnome/terminal/legacy/profiles:/list "${new_list}"
  fi

  success "GNOME Terminal profile 'Min Dark' installed (UUID: ${profile_slug})"

  # Ask to set as default
  if [[ "${MIN_DARK_SET_DEFAULT:-}" == "1" ]] || [[ "${1:-}" == "--default" ]]; then
    dconf write /org/gnome/terminal/legacy/profiles:/default "'${profile_slug}'"
    success "Set as default profile."
  else
    info "To set as default, run: dconf write /org/gnome/terminal/legacy/profiles:/default \"'${profile_slug}'\""
  fi
}

# --------------------------------------------------------------------------- #
# Oh My Zsh
# --------------------------------------------------------------------------- #
install_ohmyzsh_theme() {
  local zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
  local theme_dir="${zsh_custom}/themes/min-dark"

  if [[ ! -d "${zsh_custom}" ]]; then
    warn "Oh My Zsh custom directory not found at ${zsh_custom}. Skipping."
    return 1
  fi

  info "Installing Oh My Zsh theme..."

  mkdir -p "${theme_dir}"
  cp "${SCRIPT_DIR}/oh-my-zsh/min-dark.zsh-theme" "${theme_dir}/min-dark.zsh-theme"

  success "Theme installed at ${theme_dir}/min-dark.zsh-theme"

  # Update .zshrc if requested
  local zshrc="${HOME}/.zshrc"
  if [[ -f "$zshrc" ]]; then
    local current_theme
    current_theme=$(grep -oP '^ZSH_THEME="\K[^"]+' "$zshrc" 2>/dev/null || echo "")

    if [[ "$current_theme" == "min-dark/min-dark" ]]; then
      info "ZSH_THEME already set to min-dark/min-dark"
    elif [[ "${MIN_DARK_UPDATE_ZSHRC:-}" == "1" ]] || [[ "${1:-}" == "--update-zshrc" ]]; then
      sed -i "s|^ZSH_THEME=\".*\"|ZSH_THEME=\"min-dark/min-dark\"|" "$zshrc"
      success "Updated .zshrc theme to min-dark/min-dark (was: ${current_theme})"
    else
      info "To activate, change ZSH_THEME in ~/.zshrc:"
      echo "  ZSH_THEME=\"min-dark/min-dark\""
    fi
  fi
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
usage() {
  cat <<EOF
Min Dark Terminal — Installer

Usage: ./install.sh [options]

Options:
  --all              Install everything (GNOME Terminal + Oh My Zsh)
  --gnome            Install GNOME Terminal profile only
  --zsh              Install Oh My Zsh theme only
  --default          Set GNOME Terminal profile as default
  --update-zshrc     Update .zshrc to use the min-dark theme
  -h, --help         Show this help

Examples:
  ./install.sh --all --default --update-zshrc
  ./install.sh --gnome --default
  ./install.sh --zsh --update-zshrc

Environment variables:
  MIN_DARK_SET_DEFAULT=1    Same as --default
  MIN_DARK_UPDATE_ZSHRC=1   Same as --update-zshrc
EOF
}

main() {
  local install_gnome=0
  local install_zsh=0
  local set_default=""
  local update_zshrc=""

  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        install_gnome=1
        install_zsh=1
        ;;
      --gnome)
        install_gnome=1
        ;;
      --zsh)
        install_zsh=1
        ;;
      --default)
        set_default="--default"
        ;;
      --update-zshrc)
        update_zshrc="--update-zshrc"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  echo ""
  echo -e "  ${BLUE}Min Dark Terminal${NC}"
  echo "  Port of Min Theme by Miguel Solorio"
  echo ""

  if [[ $install_gnome -eq 1 ]]; then
    install_gnome_terminal "$set_default"
  fi

  if [[ $install_zsh -eq 1 ]]; then
    install_ohmyzsh_theme "$update_zshrc"
  fi

  echo ""
  info "Restart your terminal to apply changes."
}

main "$@"
