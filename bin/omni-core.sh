#!/usr/bin/env bash
# ==============================================================================
#  OMNI CORE — Shared Network, Hardware Detection & Utilities Engine
# ==============================================================================

export DESKTOP_IP="100.86.159.86"
export DESKTOP_MAC="34:5a:60:b6:62:e1"

export LAPTOP_IP="100.72.213.23"
export LAPTOP_MAC="70:9c:d1:5b:4a:87"

export PHONE_IP="100.118.50.88"
export PHONE_MODEL="SM-S921U1"
export PHONE_PORT="8022"
export PHONE_USER="u0_a501"

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

# ── Hardware Identification ──
omni_detect_device() {
  # 1. Check Phone Hardware Property or IP
  if command -v getprop >/dev/null 2>&1; then
    local model
    model=$(getprop ro.product.model 2>/dev/null || true)
    if [[ "$model" =~ (SM-S921|samsung|Samsung) ]] || [ -n "${TERMUX_VERSION:-}" ]; then
      echo "phone"
      return 0
    fi
  fi

  # 2. Check Interface IP or Tailscale IP
  local current_ts_ip=""
  if command -v tailscale >/dev/null 2>&1; then
    current_ts_ip=$(tailscale ip -4 2>/dev/null || true)
  elif command -v ifconfig >/dev/null 2>&1; then
    current_ts_ip=$(ifconfig 2>/dev/null | grep -oE "100\.[0-9]+\.[0-9]+\.[0-9]+" | head -n 1 || true)
  fi

  if [ "$current_ts_ip" = "$PHONE_IP" ]; then
    echo "phone"
    return 0
  elif [ "$current_ts_ip" = "$LAPTOP_IP" ]; then
    echo "laptop"
    return 0
  elif [ "$current_ts_ip" = "$DESKTOP_IP" ]; then
    echo "desktop"
    return 0
  fi

  # 3. Check Network Interface MAC Address
  local mac_list=""
  if command -v ip >/dev/null 2>&1; then
    mac_list=$(ip link 2>/dev/null | grep -i "link/ether" | awk '{print $2}' | tr '[:upper:]' '[:lower:]' || true)
  fi

  if echo "$mac_list" | grep -q "$DESKTOP_MAC"; then
    echo "desktop"
    return 0
  fi

  if echo "$mac_list" | grep -q "$LAPTOP_MAC"; then
    echo "laptop"
    return 0
  fi

  # 4. Fallback: Hostname
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

# ── Shared Banner Header ──
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
