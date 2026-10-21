#!/usr/bin/env bash
# ==============================================================================
#  OMNI CORE — Shared Network, Hardware Detection & Utilities Engine
#  Open-Source Edition (No hardcoded credentials)
# ==============================================================================

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omni"
CONFIG_FILE="$CONFIG_DIR/config.env"
export OMNI_VERSION="v1.3.0"

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

# ── Tailscale Ping / Latency ──
omni_ts_ping() {
  local target_ip="$1"
  local rtt
  rtt=$(ping -c 1 -W 1 "$target_ip" 2>/dev/null | grep -oE "time=[0-9.]+" | cut -d= -f2)
  if [ -n "$rtt" ]; then
    echo "${rtt}ms"
  else
    echo "down"
  fi
}

# ── Tmux Status Helper ──
omni_tmux_badge() {
  local session_name="$1"
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo -e "${C_GREEN}● on${C_RESET}"
  else
    echo -e "${C_DIM}○ off${C_RESET}"
  fi
}

# ── Universal Clipboard Getter ──
omni_get_clipboard() {
  if command -v termux-clipboard-get >/dev/null 2>&1; then
    termux-clipboard-get 2>/dev/null || true
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
    wl-paste 2>/dev/null || true
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o 2>/dev/null || true
  fi
}

# ── Universal Clipboard Setter ──
omni_set_clipboard() {
  local text="$1"
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    echo -n "$text" | termux-clipboard-set 2>/dev/null || true
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    echo -n "$text" | wl-copy 2>/dev/null || true
  elif command -v xclip >/dev/null 2>&1; then
    echo -n "$text" | xclip -selection clipboard 2>/dev/null || true
  fi
}

# ── Universal Wake-on-LAN (No external binary required) ──
omni_wake_mac() {
  local mac="$1"
  if [ -z "$mac" ]; then
    echo -e "${C_YELLOW}[!] MAC address is empty or not configured.${C_RESET}"
    return 1
  fi

  if command -v wakeonlan >/dev/null 2>&1; then
    wakeonlan "$mac" >/dev/null 2>&1 && return 0
  fi

  if command -v etherwake >/dev/null 2>&1; then
    etherwake "$mac" >/dev/null 2>&1 && return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import socket, sys
mac = '$mac'.replace(':', '').replace('-', '')
if len(mac) != 12:
    sys.exit(1)
payload = bytes.fromhex('f' * 12 + mac * 16)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
s.sendto(payload, ('255.255.255.255', 9))
" >/dev/null 2>&1 && return 0
  fi

  return 1
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
  echo -e " ${C_BOLD}OMNI System Control${C_RESET} ${C_YELLOW}${OMNI_VERSION:-v1.3.0}${C_RESET} │ ${C_BOLD}Device:${C_RESET} ${C_GREEN}${dev_name}${C_RESET} ${extra_info}"
  echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
}

# Auto-detect Wayland socket if unset
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  for w in "$XDG_RUNTIME_DIR"/wayland-*; do
    if [ -S "$w" ]; then
      export WAYLAND_DISPLAY=$(basename "$w")
      break
    fi
  done
fi

# ── Dynamic Shell Command Execution ──
omni_exec_custom() {
  local input="$1"
  if [ -z "$input" ]; then
    return 1
  fi

  local cmd
  cmd=$(echo "$input" | awk '{print $1}')

  if command -v "$cmd" >/dev/null 2>&1 || [[ "$cmd" =~ ^(cd|export|alias|echo|source|\.)$ ]]; then
    echo -e "\n${C_CYAN}─── Running: ${C_BOLD}$input${C_RESET}${C_CYAN} ───${C_RESET}"
    eval "$input"
    local ret=$?
    echo -e "${C_CYAN}─── Exited with code $ret ───${C_RESET}"
    return 0
  fi
  return 1
}

# ── Built-in Self-Updater ──
omni_run_update() {
  local dev
  dev=$(omni_detect_device)
  echo -e "${C_CYAN}${C_BOLD}=== OMNI CLI Self-Updater ($dev) ===${C_RESET}\n"

  case "$dev" in
    desktop)
      echo -e "${C_CYAN}[1/3] Checking dotfiles git repo...${C_RESET}"
      if [ -d "$HOME/dotfiles/.git" ]; then
        git -C "$HOME/dotfiles" pull --rebase origin main 2>/dev/null && \
          echo -e "${C_GREEN}[✓] Dotfiles repository up to date!${C_RESET}" || \
          echo -e "${C_YELLOW}[!] Git pull skipped or local changes exist.${C_RESET}"
      fi

      echo -e "${C_CYAN}[2/3] Verifying ~/.local/bin symlinks...${C_RESET}"
      mkdir -p "$HOME/.local/bin" 2>/dev/null
      for f in "$HOME/dotfiles/bin/omni"*; do
        [ -f "$f" ] || continue
        chmod +x "$f"
        bname=$(basename "$f")
        ln -sf "$f" "$HOME/.local/bin/$bname"
      done
      echo -e "${C_GREEN}[✓] Desktop symlinks verified.${C_RESET}"

      echo -e "${C_CYAN}[3/3] Checking phone synchronization...${C_RESET}"
      if omni_is_online "$PHONE_IP"; then
        echo -e "${C_CYAN}[*] S24 is online ($PHONE_IP). Pushing updates over SSH...${C_RESET}"
        scp -P "$PHONE_PORT" -r "$HOME/dotfiles/bin"/omni* "${PHONE_USER}@${PHONE_IP}:~/bin/" 2>/dev/null && \
          echo -e "${C_GREEN}[✓] Phone successfully synced!${C_RESET}" || \
          echo -e "${C_YELLOW}[!] Phone sync failed (check SSH key/port).${C_RESET}"
      else
        echo -e "${C_DIM}[-] S24 Phone is currently offline. Skipping push.${C_RESET}"
      fi
      ;;

    laptop)
      echo -e "${C_CYAN}[1/2] Pulling latest dotfiles from Git...${C_RESET}"
      if [ -d "$HOME/dotfiles/.git" ]; then
        cd "$HOME/dotfiles" && git pull --rebase origin main && \
          echo -e "${C_GREEN}[✓] Dotfiles updated!${C_RESET}" || \
          echo -e "${C_RED}[!] Git pull failed.${C_RESET}"
      fi

      echo -e "${C_CYAN}[2/2] Updating ~/.local/bin symlinks...${C_RESET}"
      mkdir -p "$HOME/.local/bin" 2>/dev/null
      for f in "$HOME/dotfiles/bin/omni"*; do
        [ -f "$f" ] || continue
        chmod +x "$f"
        bname=$(basename "$f")
        ln -sf "$f" "$HOME/.local/bin/$bname"
      done
      echo -e "${C_GREEN}[✓] Laptop symlinks updated.${C_RESET}"
      ;;

    phone)
      echo -e "${C_CYAN}[1/1] Syncing from Desktop over SSH...${C_RESET}"
      if command -v sync-down >/dev/null 2>&1; then
        sync-down
      elif [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
        scp "${DESKTOP_USER}@${DESKTOP_IP}:~/dotfiles/bin/omni*" ~/bin/ 2>/dev/null && \
          chmod +x ~/bin/omni* && \
          echo -e "${C_GREEN}[✓] Phone updated from Desktop!${C_RESET}" || \
          echo -e "${C_RED}[!] Download failed.${C_RESET}"
      else
        echo -e "${C_RED}[!] Desktop is unreachable.${C_RESET}"
      fi
      ;;
  esac

  echo -e "\n${C_GREEN}${C_BOLD}[✓] Omni CLI is fully up to date!${C_RESET}"
}
