#!/usr/bin/env bash
# ==============================================================================
#  OMNI CORE — Shared Network, Hardware Detection & Utilities Engine
#  Open-Source Edition (No hardcoded credentials)
# ==============================================================================

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omni"
CONFIG_FILE="$CONFIG_DIR/config.env"

# Colors
export C_RESET="\033[0m"
export C_BOLD="\033[1m"
export C_CYAN="\033[1;36m"
export C_GREEN="\033[1;32m"
export C_RED="\033[1;31m"
export C_YELLOW="\033[1;33m"
export C_BLUE="\033[1;34m"
export C_MAGENTA="\033[1;35m"
export C_DIM="\033[2m"

# ── Interactive Setup Wizard ──
omni_run_setup() {
  clear
  echo -e "${C_CYAN}${C_BOLD}=== OMNI CLI First-Time Setup ===${C_RESET}\n"
  echo "No configuration found at $CONFIG_FILE."
  echo "Let's configure your multi-device network endpoints."
  echo ""

  mkdir -p "$CONFIG_DIR"

  read -r -p "Desktop Tailscale/Local IP: " d_ip
  read -r -p "Desktop MAC Address (optional, press Enter to skip): " d_mac
  read -r -p "Desktop SSH Username [${USER}]: " d_user
  d_user="${d_user:-$USER}"

  echo ""
  read -r -p "Laptop Tailscale/Local IP: " l_ip
  read -r -p "Laptop MAC Address (optional, press Enter to skip): " l_mac
  read -r -p "Laptop SSH Username [${USER}]: " l_user
  l_user="${l_user:-$USER}"

  echo ""
  read -r -p "Phone (Termux) Tailscale IP: " p_ip
  read -r -p "Phone SSH Port [8022]: " p_port
  p_port="${p_port:-8022}"
  read -r -p "Phone SSH Username (e.g. u0_a...): " p_user

  cat << CONF > "$CONFIG_FILE"
# OMNI Fleet Configuration
DESKTOP_IP="${d_ip}"
DESKTOP_MAC="${d_mac}"
DESKTOP_USER="${d_user}"

LAPTOP_IP="${l_ip}"
LAPTOP_MAC="${l_mac}"
LAPTOP_USER="${l_user}"

PHONE_IP="${p_ip}"
PHONE_PORT="${p_port}"
PHONE_USER="${p_user}"

DESKTOP_DOWNLOADS="\$HOME/Downloads"
LAPTOP_DOWNLOADS="\$HOME/Downloads"
PHONE_DOWNLOADS="\$HOME/storage/downloads"
CONF

  chmod 600 "$CONFIG_FILE"
  echo -e "\n${C_GREEN}[✓] Configuration saved to $CONFIG_FILE!${C_RESET}\n"
  sleep 1.2
}

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
else
  omni_run_setup
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# Fallback defaults
export DESKTOP_IP="${DESKTOP_IP:-127.0.0.1}"
export DESKTOP_MAC="${DESKTOP_MAC:-}"
export DESKTOP_USER="${DESKTOP_USER:-$USER}"

export LAPTOP_IP="${LAPTOP_IP:-127.0.0.1}"
export LAPTOP_MAC="${LAPTOP_MAC:-}"
export LAPTOP_USER="${LAPTOP_USER:-$USER}"

export PHONE_IP="${PHONE_IP:-127.0.0.1}"
export PHONE_PORT="${PHONE_PORT:-8022}"
export PHONE_USER="${PHONE_USER:-}"

# ── Hardware Identification ──
omni_detect_device() {
  # 1. Android Check
  if command -v getprop >/dev/null 2>&1 || [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux" ]; then
    echo "phone"
    return 0
  fi

  # 2. Tailscale / Interface IP Match
  local current_ts_ip=""
  if command -v tailscale >/dev/null 2>&1; then
    current_ts_ip=$(tailscale ip -4 2>/dev/null || true)
  elif command -v ifconfig >/dev/null 2>&1; then
    current_ts_ip=$(ifconfig 2>/dev/null | grep -oE "100\.[0-9]+\.[0-9]+\.[0-9]+" | head -n 1 || true)
  fi

  if [ -n "$current_ts_ip" ]; then
    if [ "$current_ts_ip" = "$PHONE_IP" ]; then
      echo "phone"; return 0
    elif [ "$current_ts_ip" = "$LAPTOP_IP" ]; then
      echo "laptop"; return 0
    elif [ "$current_ts_ip" = "$DESKTOP_IP" ]; then
      echo "desktop"; return 0
    fi
  fi

  # 3. MAC Address Match
  if [ -n "$DESKTOP_MAC" ] || [ -n "$LAPTOP_MAC" ]; then
    local mac_list=""
    if command -v ip >/dev/null 2>&1; then
      mac_list=$(ip link 2>/dev/null | grep -i "link/ether" | awk '{print $2}' | tr '[:upper:]' '[:lower:]' || true)
    fi
    if [ -n "$DESKTOP_MAC" ] && echo "$mac_list" | grep -q "${DESKTOP_MAC,,}"; then
      echo "desktop"; return 0
    fi
    if [ -n "$LAPTOP_MAC" ] && echo "$mac_list" | grep -q "${LAPTOP_MAC,,}"; then
      echo "laptop"; return 0
    fi
  fi

  # 4. Hostname Fallback
  local hname
  hname=$(hostname 2>/dev/null || echo "")
  if [[ "$hname" =~ (laptop|jordanslaptop|omarchy-laptop) ]]; then
    echo "laptop"
    return 0
  fi

  echo "desktop"
}

# ── Network Check ──
omni_is_online() {
  local target_ip="$1"
  ping -c 1 -W 1 "$target_ip" >/dev/null 2>&1
}

# ── Banner Header ──
omni_render_header() {
  local dev_name="$1"
  local extra_info="${2:-}"
  clear
  echo -e "${C_CYAN}"
  cat << "BANNER"
  ___  __  __ _   _ ___   ____ _     ___ 
 / _ \|  \/  | \ | |_ _| / ___| |   |_ _|
| | | | |\/| |  \| || | | |   | |    | | 
| |_| | |  | | |\  || | | |___| |___ | | 
 \___/|_|  |_|_| \_|___| \____|_____|___|
BANNER
  echo -e "${C_RESET}${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
  echo -e " ${C_BOLD}OMNI System Control${C_RESET} │ ${C_BOLD}Device:${C_RESET} ${C_GREEN}${dev_name}${C_RESET} ${extra_info}"
  echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
}
