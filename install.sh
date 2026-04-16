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
# Distro detection & dependency bootstrap
# --------------------------------------------------------------------------- #
DISTRO_ID=""
DISTRO_LIKE=""
PKG_MANAGER=""
INSTALL_CMD=""

detect_distro() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID="unknown"
    DISTRO_LIKE=""
  fi

  case "$DISTRO_ID $DISTRO_LIKE" in
    *arch*|*manjaro*)
      PKG_MANAGER="pacman"
      INSTALL_CMD="sudo pacman -S --needed --noconfirm"
      ;;
    *debian*|*ubuntu*)
      PKG_MANAGER="apt"
      INSTALL_CMD="sudo apt install -y"
      ;;
    *)
      PKG_MANAGER=""
      INSTALL_CMD=""
      ;;
  esac

  if [[ -n "$PKG_MANAGER" ]]; then
    info "Detected distro: ${DISTRO_ID} (using ${PKG_MANAGER})"
  else
    warn "Unrecognized distro: ${DISTRO_ID}. Missing dependencies must be installed manually."
  fi
}

# Map abstract target -> native package name for the detected package manager.
pkg_name_for() {
  local target="$1"
  case "$PKG_MANAGER:$target" in
    apt:dconf)             echo "dconf-cli" ;;
    apt:uuidgen)           echo "uuid-runtime" ;;
    apt:gnome-terminal)    echo "gnome-terminal" ;;
    apt:zsh)               echo "zsh" ;;
    apt:curl)              echo "curl" ;;
    pacman:dconf)          echo "dconf" ;;
    pacman:uuidgen)        echo "util-linux" ;;
    pacman:gnome-terminal) echo "gnome-terminal" ;;
    pacman:zsh)            echo "zsh" ;;
    pacman:curl)           echo "curl" ;;
    *) echo "" ;;
  esac
}

# ensure_dep <command> <friendly-name>
# Returns 0 if the command is available (or was just installed), 1 otherwise.
ensure_dep() {
  local cmd="$1" friendly="$2"
  command -v "$cmd" &>/dev/null && return 0

  local pkg
  pkg=$(pkg_name_for "$cmd")
  if [[ -z "$PKG_MANAGER" || -z "$pkg" ]]; then
    warn "${friendly} not found and distro not recognized. Install '${cmd}' manually and rerun."
    return 1
  fi

  warn "${friendly} (${cmd}) not found."
  read -r -p "Install with '${INSTALL_CMD} ${pkg}'? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    # shellcheck disable=SC2086
    if ! $INSTALL_CMD $pkg; then
      error "Failed to install ${pkg}"
      return 1
    fi
    success "${pkg} installed."
    # Re-check after install, in case the binary lives in a path hash missed.
    hash -r 2>/dev/null || true
    command -v "$cmd" &>/dev/null && return 0
    warn "${cmd} still not in PATH after install."
    return 1
  fi

  warn "Skipping — install '${pkg}' manually and rerun."
  return 1
}

# Install Oh My Zsh itself (not via pkg manager — uses the official script).
ensure_ohmyzsh() {
  [[ -d "${HOME}/.oh-my-zsh" ]] && return 0

  warn "Oh My Zsh not installed."
  read -r -p "Install via official script now? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    warn "Skipping Oh My Zsh theme. Install from https://ohmyz.sh/ and rerun."
    return 1
  fi

  ensure_dep zsh "Zsh shell" || return 1
  ensure_dep curl "curl" || return 1

  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
}

# Clone a Zsh plugin repo into $ZSH_CUSTOM/plugins/<name> if missing.
clone_zsh_plugin() {
  local repo="$1" name="$2"
  local zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
  local dest="${zsh_custom}/plugins/${name}"

  [[ -d "$dest" ]] && return 0
  ensure_dep git "Git" || return 1

  info "Cloning ${name}..."
  if ! git clone --depth=1 --quiet "$repo" "$dest"; then
    warn "Failed to clone ${name}"
    return 1
  fi
  success "Plugin ${name} installed at ${dest}"
}

# Enable a plugin in ~/.zshrc by inserting it into the plugins=(...) list.
# Idempotent: does nothing if the plugin name is already present.
enable_zsh_plugin() {
  local plugin="$1"
  local zshrc="${HOME}/.zshrc"
  [[ -f "$zshrc" ]] || return 1

  if grep -qE "^plugins=\([^)]*\b${plugin}\b[^)]*\)" "$zshrc"; then
    return 0
  fi

  if grep -qE '^plugins=\([^)]*\)' "$zshrc"; then
    sed -i -E "s|^(plugins=\([^)]*)\)|\1 ${plugin})|" "$zshrc"
    success "Enabled '${plugin}' in .zshrc plugins list."
  else
    info "Could not auto-edit plugins=(...) in .zshrc. Add '${plugin}' manually."
  fi
}

# Install the two prompt-sugar plugins that pair well with the min-dark theme.
# syntax-highlighting must be LAST in the plugins list — enable order matters.
install_companion_plugins() {
  clone_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions     zsh-autosuggestions     || true
  clone_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting || true

  enable_zsh_plugin zsh-autosuggestions
  enable_zsh_plugin zsh-syntax-highlighting
}

# --------------------------------------------------------------------------- #
# GNOME Terminal
# --------------------------------------------------------------------------- #
install_gnome_terminal() {
  ensure_dep dconf "dconf" || return 1
  ensure_dep uuidgen "uuidgen" || return 1
  ensure_dep gnome-terminal "GNOME Terminal" || return 1

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
  ensure_ohmyzsh || return 1
  install_companion_plugins

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

  detect_distro

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
