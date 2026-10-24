#!/usr/bin/env bash
# ==============================================================================
#  OMNI CORE — Shared Network, Hardware Detection & Utilities Engine
#  Open-Source Edition (No hardcoded credentials)
# ==============================================================================

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omni"
CONFIG_FILE="$CONFIG_DIR/config.env"
CUSTOM_TOOLS_FILE="$CONFIG_DIR/custom_tools.conf"
export OMNI_VERSION="v1.4.0"

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
  echo -e "${C_CYAN}${C_BOLD}"
  cat << "BANNER"
  ___  __  __ _   _ ___   ____ ___  _   _ _____ ___ ____ 
 / _ \|  \/  | \ | |_ _| / ___/ _ \| \ | |  ___|_ _/ ___|
| | | | |\/| |  \| || | | |  | | | |  \| | |_   | | |  _ 
| |_| | |  | | |\  || | | |__| |_| | |\  |  _|  | | |_| |
 \___/|_|  |_|_| \_|___| \____\___/|_| \_|_|   |___\____|
BANNER
  echo -e "${C_RESET}${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
  echo -e " ${C_BOLD}OMNI System Onboarding & Hardware Configuration Wizard${C_RESET}"
  echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}\n"

  mkdir -p "$CONFIG_DIR"

  # ── STEP 1: Local Device Role & Identity ──
  echo -e "${C_CYAN}${C_BOLD}[1/6] Local Device Role & Identity${C_RESET}"
  local cur_host="$(hostname 2>/dev/null || echo "unknown")"
  local cur_user="${USER:-$(whoami)}"
  echo -e "Detected Host: ${C_GREEN}${cur_host}${C_RESET} | User: ${C_GREEN}${cur_user}${C_RESET} | OS: ${C_GREEN}$(uname -s)${C_RESET}"
  echo ""
  echo "What role does this specific machine play in your fleet?"
  echo -e "  ${C_CYAN}[1]${C_RESET} Desktop Workstation (Primary Rig / Multi-Monitor)"
  echo -e "  ${C_CYAN}[2]${C_RESET} Laptop (Portable Rig / Travel)"
  echo -e "  ${C_CYAN}[3]${C_RESET} Headless Server / Homelab Node"
  echo -e "  ${C_CYAN}[4]${C_RESET} Android Phone (Termux Environment)"
  local role_choice
  read -r -p "Select role [1-4, default: 1]: " role_choice
  role_choice="${role_choice:-1}"

  local this_role="desktop"
  case "$role_choice" in
    2) this_role="laptop" ;;
    3) this_role="server" ;;
    4) this_role="phone" ;;
    *) this_role="desktop" ;;
  esac
  echo -e "${C_GREEN}[✓] This device assigned as: ${C_BOLD}${this_role}${C_RESET}\n"

  # ── STEP 2: Hardware Network Interface & MAC Pairing ──
  echo -e "${C_CYAN}${C_BOLD}[2/6] Hardware MAC Address Pairing (for Wake-on-LAN & Identity)${C_RESET}"
  echo "Scanning local physical network interfaces..."

  local ifaces=()
  local macs=()
  local states=()
  local iface_count=0

  for iface_path in /sys/class/net/*; do
    [ -d "$iface_path" ] || continue
    local iname
    iname=$(basename "$iface_path")
    [[ "$iname" =~ ^(lo|docker.*|veth.*|br-.*|virbr.*|tailscale.*|wg.*)$ ]] && continue
    [ -f "$iface_path/address" ] || continue
    local imac
    imac=$(cat "$iface_path/address" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    [ -z "$imac" ] || [ "$imac" = "00:00:00:00:00:00" ] && continue
    local istate="unknown"
    [ -f "$iface_path/operstate" ] && istate=$(cat "$iface_path/operstate")

    ifaces+=("$iname")
    macs+=("$imac")
    states+=("$istate")
    iface_count=$((iface_count + 1))
    echo -e "  ${C_CYAN}[$iface_count]${C_RESET} ${C_BOLD}${iname}${C_RESET} ➜ MAC: ${C_YELLOW}${imac}${C_RESET} (State: ${istate})"
  done

  local this_mac=""
  local chosen_iface=""
  if [ $iface_count -gt 0 ]; then
    echo -e "  ${C_CYAN}[m]${C_RESET} Enter custom MAC manually"
    echo -e "  ${C_CYAN}[s]${C_RESET} Skip MAC address binding"
    local nic_choice
    read -r -p "Select primary network interface [1-$iface_count, default: 1]: " nic_choice
    nic_choice="${nic_choice:-1}"

    if [[ "$nic_choice" =~ ^[0-9]+$ ]] && [ "$nic_choice" -le "$iface_count" ] && [ "$nic_choice" -ge 1 ]; then
      local idx=$((nic_choice - 1))
      this_mac="${macs[$idx]}"
      chosen_iface="${ifaces[$idx]}"
      echo -e "${C_GREEN}[✓] Selected interface ${chosen_iface} with MAC: ${this_mac}${C_RESET}"
    elif [[ "$nic_choice" =~ ^[mM]$ ]]; then
      read -r -p "Enter custom MAC address (e.g. 00:11:22:33:44:55): " this_mac
    else
      echo -e "${C_DIM}Skipped MAC address binding for this device.${C_RESET}"
    fi
  else
    read -r -p "No physical interfaces detected. Enter MAC address (or Enter to skip): " this_mac
  fi

  # Check Wake-on-LAN capability if ethtool is available
  if [ -n "$chosen_iface" ] && command -v ethtool >/dev/null 2>&1; then
    local wol_info
    wol_info=$(ethtool "$chosen_iface" 2>/dev/null | grep -i "Wake-on:" || true)
    if [ -n "$wol_info" ]; then
      if echo "$wol_info" | grep -q "g"; then
        echo -e "${C_GREEN}[✓] Wake-on-LAN is active on ${chosen_iface} (Magic Packet enabled).${C_RESET}"
      else
        echo -e "${C_YELLOW}[!] Wake-on-LAN is not enabled with magic packet on ${chosen_iface}.${C_RESET}"
        read -r -p "Enable Wake-on-LAN ('wol g') on ${chosen_iface}? (y/N): " set_wol
        if [[ "$set_wol" =~ ^[Yy]$ ]]; then
          sudo ethtool -s "$chosen_iface" wol g 2>/dev/null && echo -e "${C_GREEN}[✓] WoL enabled!${C_RESET}" || echo -e "${C_YELLOW}[!] Could not enable WoL (requires sudo).${C_RESET}"
        fi
      fi
    fi
  fi
  echo ""

  # ── STEP 3: Tailscale Mesh Capability ──
  echo -e "${C_CYAN}${C_BOLD}[3/6] Tailscale Network Integration${C_RESET}"
  local self_ts_ip=""
  if ! command -v tailscale >/dev/null 2>&1; then
    echo -e "${C_YELLOW}[!] Tailscale is not currently installed.${C_RESET}"
    echo "Tailscale securely connects your devices peer-to-peer across any network with WireGuard."
    read -r -p "Would you like to install Tailscale now? (y/N): " inst_ts
    if [[ "$inst_ts" =~ ^[Yy]$ ]]; then
      if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed tailscale && sudo systemctl enable --now tailscaled
      elif command -v apt-get >/dev/null 2>&1; then
        curl -fsSL https://tailscale.com/install.sh | sh
      else
        curl -fsSL https://tailscale.com/install.sh | sh
      fi
    fi
  fi

  if command -v tailscale >/dev/null 2>&1; then
    if ! tailscale status >/dev/null 2>&1; then
      echo -e "${C_YELLOW}[!] Tailscale is installed but inactive or not authenticated.${C_RESET}"
      read -r -p "Run 'sudo tailscale up' now to authenticate? (y/N): " run_up
      if [[ "$run_up" =~ ^[Yy]$ ]]; then
        sudo tailscale up
      fi
    fi

    if tailscale status >/dev/null 2>&1; then
      self_ts_ip=$(tailscale ip -4 2>/dev/null || true)
      echo -e "${C_GREEN}[✓] Tailscale is connected! This node's IP: ${C_BOLD}${self_ts_ip:-none}${C_RESET}"
      echo -e "\n${C_DIM}Discovered Tailnet nodes:${C_RESET}"
      tailscale status 2>/dev/null | head -n 8 | sed 's/^/  /'
    fi
  fi
  echo ""

  # ── STEP 4: Fleet Device Endpoints & Credentials ──
  echo -e "${C_CYAN}${C_BOLD}[4/6] Fleet Peer Endpoints & Credentials${C_RESET}"
  echo "Configure IP addresses and SSH endpoints for your fleet nodes."

  # Initialize current values or sensible defaults
  local d_ip="${DESKTOP_IP:-127.0.0.1}"
  local d_mac="${DESKTOP_MAC:-}"
  local d_user="${DESKTOP_USER:-$cur_user}"

  local l_ip="${LAPTOP_IP:-127.0.0.1}"
  local l_mac="${LAPTOP_MAC:-}"
  local l_user="${LAPTOP_USER:-$cur_user}"

  local p_ip="${PHONE_IP:-127.0.0.1}"
  local p_port="${PHONE_PORT:-8022}"
  local p_user="${PHONE_USER:-}"

  # If this node was assigned a role, auto-fill its own IP & MAC
  if [ "$this_role" = "desktop" ]; then
    [ -n "$self_ts_ip" ] && d_ip="$self_ts_ip"
    [ -n "$this_mac" ] && d_mac="$this_mac"
    d_user="$cur_user"
  elif [ "$this_role" = "laptop" ]; then
    [ -n "$self_ts_ip" ] && l_ip="$self_ts_ip"
    [ -n "$this_mac" ] && l_mac="$this_mac"
    l_user="$cur_user"
  elif [ "$this_role" = "phone" ]; then
    [ -n "$self_ts_ip" ] && p_ip="$self_ts_ip"
    p_user="$cur_user"
  fi

  # Auto-suggest from tailscale peers if peer is default
  if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
    while read -r ts_peer_ip ts_peer_host rest; do
      if [[ "$ts_peer_host" =~ (desktop|workstation) ]] && [ "$this_role" != "desktop" ] && [ "$d_ip" = "127.0.0.1" ]; then
        d_ip="$ts_peer_ip"
      elif [[ "$ts_peer_host" =~ (laptop) ]] && [ "$this_role" != "laptop" ] && [ "$l_ip" = "127.0.0.1" ]; then
        l_ip="$ts_peer_ip"
      elif [[ "$ts_peer_host" =~ (phone|s24|termux|android) ]] && [ "$this_role" != "phone" ] && [ "$p_ip" = "127.0.0.1" ]; then
        p_ip="$ts_peer_ip"
      fi
    done < <(tailscale status 2>/dev/null || true)
  fi

  echo -e "\n${C_BOLD}Desktop Workstation:${C_RESET}"
  read -r -p "  Desktop IP [${d_ip}]: " input_d_ip; d_ip="${input_d_ip:-$d_ip}"
  read -r -p "  Desktop MAC (for Wake-on-LAN) [${d_mac}]: " input_d_mac; d_mac="${input_d_mac:-$d_mac}"
  read -r -p "  Desktop SSH User [${d_user}]: " input_d_user; d_user="${input_d_user:-$d_user}"

  echo -e "\n${C_BOLD}Laptop Workstation:${C_RESET}"
  read -r -p "  Laptop IP [${l_ip}]: " input_l_ip; l_ip="${input_l_ip:-$l_ip}"
  read -r -p "  Laptop MAC (for Wake-on-LAN) [${l_mac}]: " input_l_mac; l_mac="${input_l_mac:-$l_mac}"
  read -r -p "  Laptop SSH User [${l_user}]: " input_l_user; l_user="${input_l_user:-$l_user}"

  echo -e "\n${C_BOLD}Android Phone (Termux):${C_RESET}"
  read -r -p "  Phone IP [${p_ip}]: " input_p_ip; p_ip="${input_p_ip:-$p_ip}"
  read -r -p "  Phone SSH Port [${p_port}]: " input_p_port; p_port="${input_p_port:-$p_port}"
  read -r -p "  Phone SSH User [${p_user}]: " input_p_user; p_user="${input_p_user:-$p_user}"

  echo ""
  # ── STEP 5: Area Preferences & Preferred Tools ──
  echo -e "${C_CYAN}${C_BOLD}[5/6] Menu Area Preferences & Tool Selections${C_RESET}"
  echo "Customize which sections appear on your Omni interactive menu."

  local pref_ai="${OMNI_ENABLE_AI:-true}"
  local pref_fleet="${OMNI_ENABLE_FLEET:-true}"
  local pref_sys="${OMNI_ENABLE_SYSTEM:-true}"
  local pref_clip="${OMNI_ENABLE_CLIPBOARD:-true}"

  read -r -p "Enable AI & Copilot Hub? (Y/n) [${pref_ai}]: " in_ai
  [[ "$in_ai" =~ ^[Nn]$ ]] && pref_ai="false" || pref_ai="true"

  local sel_ai_engine="${OMNI_AI_ENGINE:-agy}"
  if [ "$pref_ai" = "true" ]; then
    echo "  Available AI engines: [1] Antigravity (agy)  [2] Claude Code (claude)  [3] Aider (aider)  [4] Ollama"
    read -r -p "  Preferred AI Engine [1-4, default: 1]: " in_engine
    case "$in_engine" in
      2) sel_ai_engine="claude" ;;
      3) sel_ai_engine="aider" ;;
      4) sel_ai_engine="ollama" ;;
      *) sel_ai_engine="agy" ;;
    esac
  fi

  read -r -p "Enable Multi-Device Remote Fleet Hub? (Y/n) [${pref_fleet}]: " in_fl
  [[ "$in_fl" =~ ^[Nn]$ ]] && pref_fleet="false" || pref_fleet="true"

  read -r -p "Enable System, Desktop & Media Controls? (Y/n) [${pref_sys}]: " in_sy
  [[ "$in_sy" =~ ^[Nn]$ ]] && pref_sys="false" || pref_sys="true"

  local sel_sys_mon="${OMNI_SYS_MONITOR:-htop}"
  if [ "$pref_sys" = "true" ]; then
    echo "  Available Monitors: [1] htop  [2] btop  [3] fastfetch  [4] desk-status"
    read -r -p "  Preferred System Monitor [1-4, default: 1]: " in_mon
    case "$in_mon" in
      2) sel_sys_mon="btop" ;;
      3) sel_sys_mon="fastfetch" ;;
      4) sel_sys_mon="desk-status" ;;
      *) sel_sys_mon="htop" ;;
    esac
  fi

  read -r -p "Enable Universal Clipboard & Notes Hub? (Y/n) [${pref_clip}]: " in_cl
  [[ "$in_cl" =~ ^[Nn]$ ]] && pref_clip="false" || pref_clip="true"

  local vault_path="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
  if [ "$pref_clip" = "true" ]; then
    read -r -p "  Obsidian Vault Directory [${vault_path}]: " in_vpath
    vault_path="${in_vpath:-$vault_path}"
  fi

  echo ""
  # ── STEP 6: Custom Tools Configuration ──
  echo -e "${C_CYAN}${C_BOLD}[6/6] Custom User Tools & Hotkey Shortcuts${C_RESET}"
  echo -e "Omni lets you map your own custom terminal commands directly into the menu via:"
  echo -e "  ${C_CYAN}${CUSTOM_TOOLS_FILE}${C_RESET}"

  if [ ! -f "$CUSTOM_TOOLS_FILE" ]; then
    cat << 'TOOLS_CONF' > "$CUSTOM_TOOLS_FILE"
# ==============================================================================
#  OMNI CLI — Custom User Tools & Hotkey Shortcuts
# ==============================================================================
# Format: <hotkey> | <display_label> | <shell_command>
#
# Examples:
# g | 🐙 Lazygit Git UI           | lazygit
# d | 🐳 Lazydocker Containers    | lazydocker
# k | ☸️  K9s Kubernetes TUI       | k9s
# b | 🌐 Open GitHub              | xdg-open https://github.com
# ==============================================================================
TOOLS_CONF
    echo -e "${C_GREEN}[✓] Initialized starter ${CUSTOM_TOOLS_FILE}${C_RESET}"
  fi

  read -r -p "Would you like to register a custom command hotkey now? (y/N): " add_tool
  if [[ "$add_tool" =~ ^[Yy]$ ]]; then
    read -r -p "  Hotkey key (e.g. 'g'): " u_key
    read -r -p "  Display Label (e.g. '🐙 Lazygit'): " u_label
    read -r -p "  Shell Command to run (e.g. 'lazygit'): " u_cmd
    if [ -n "$u_key" ] && [ -n "$u_cmd" ]; then
      echo "${u_key} | ${u_label:-$u_cmd} | ${u_cmd}" >> "$CUSTOM_TOOLS_FILE"
      echo -e "${C_GREEN}[✓] Added custom tool [${u_key}] -> ${u_cmd}${C_RESET}"
    fi
  fi

  echo ""
  # ── Save Configuration ──
  cat << CONF > "$CONFIG_FILE"
# ==============================================================================
#  OMNI Fleet Configuration (Generated: $(date))
#  Mode: 600 - Private Local Configuration (Do NOT commit to git)
# ==============================================================================

# Hardware Identity
THIS_DEVICE_ROLE="${this_role}"

# Desktop Workstation
DESKTOP_IP="${d_ip}"
DESKTOP_MAC="${d_mac}"
DESKTOP_USER="${d_user}"
DESKTOP_DOWNLOADS="\$HOME/Downloads"

# Laptop Workstation
LAPTOP_IP="${l_ip}"
LAPTOP_MAC="${l_mac}"
LAPTOP_USER="${l_user}"
LAPTOP_DOWNLOADS="\$HOME/Downloads"

# Phone (Termux)
PHONE_IP="${p_ip}"
PHONE_PORT="${p_port}"
PHONE_USER="${p_user}"
PHONE_DOWNLOADS="\$HOME/storage/downloads"

# Menu Area Preferences
OMNI_ENABLE_AI="${pref_ai}"
OMNI_ENABLE_FLEET="${pref_fleet}"
OMNI_ENABLE_SYSTEM="${pref_sys}"
OMNI_ENABLE_CLIPBOARD="${pref_clip}"

# Tool Selections
OMNI_AI_ENGINE="${sel_ai_engine}"
OMNI_SYS_MONITOR="${sel_sys_mon}"
OBSIDIAN_VAULT_PATH="${vault_path}"
CONF

  chmod 600 "$CONFIG_FILE"
  echo -e "${C_GREEN}${C_BOLD}[✓] Configuration saved to $CONFIG_FILE (Mode 600).${C_RESET}\n"

  # Optional SSH Key Exchange Offer
  read -r -p "Would you like to test or set up passwordless SSH pairing to remote peers now? (y/N): " do_pair
  if [[ "$do_pair" =~ ^[Yy]$ ]]; then
    if [ "$this_role" != "desktop" ] && [ "$d_ip" != "127.0.0.1" ]; then
      omni_pair_device "$d_user" "$d_ip" 22
    fi
    if [ "$this_role" != "laptop" ] && [ "$l_ip" != "127.0.0.1" ]; then
      omni_pair_device "$l_user" "$l_ip" 22
    fi
    if [ "$this_role" != "phone" ] && [ "$p_ip" != "127.0.0.1" ]; then
      omni_pair_device "$p_user" "$p_ip" "$p_port"
    fi
  fi

  # Connectivity Summary
  echo -e "\n${C_CYAN}─── Peer Connectivity Verification ───${C_RESET}"
  [ "$d_ip" != "127.0.0.1" ] && { omni_is_online "$d_ip" && echo -e "  Desktop (${d_ip}): ${C_GREEN}ONLINE ($(omni_ts_ping "$d_ip"))${C_RESET}" || echo -e "  Desktop (${d_ip}): ${C_RED}OFFLINE / UNREACHABLE${C_RESET}"; }
  [ "$l_ip" != "127.0.0.1" ] && { omni_is_online "$l_ip" && echo -e "  Laptop  (${l_ip}): ${C_GREEN}ONLINE ($(omni_ts_ping "$l_ip"))${C_RESET}" || echo -e "  Laptop  (${l_ip}): ${C_RED}OFFLINE / UNREACHABLE${C_RESET}"; }
  [ "$p_ip" != "127.0.0.1" ] && { omni_is_online "$p_ip" && echo -e "  Phone   (${p_ip}): ${C_GREEN}ONLINE ($(omni_ts_ping "$p_ip"))${C_RESET}" || echo -e "  Phone   (${p_ip}): ${C_RED}OFFLINE / UNREACHABLE${C_RESET}"; }

  echo -e "\n${C_GREEN}${C_BOLD}[✓] Omni onboarding complete! Run 'omni' anytime to launch the menu.${C_RESET}"
  sleep 1.5
}

# ── Passwordless SSH Pairing Assistant ──
omni_pair_device() {
  local target_user="$1"
  local target_ip="$2"
  local target_port="${3:-22}"

  if [ -z "$target_ip" ] || [ "$target_ip" = "127.0.0.1" ]; then
    echo -e "${C_YELLOW}[!] Target IP not configured.${C_RESET}"
    return 1
  fi

  echo -e "\n${C_CYAN}─── Setting up passwordless SSH to ${target_user}@${target_ip}:${target_port} ───${C_RESET}"

  local pubkey=""
  for k in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    if [ -f "$k" ]; then
      pubkey="$k"
      break
    fi
  done

  if [ -z "$pubkey" ]; then
    echo -e "${C_YELLOW}[!] No SSH key found. Generating ed25519 key pair...${C_RESET}"
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
    pubkey="$HOME/.ssh/id_ed25519.pub"
  fi

  echo -e "${C_CYAN}[*] Copying public key ($pubkey)...${C_RESET}"
  if command -v ssh-copy-id >/dev/null 2>&1; then
    ssh-copy-id -p "$target_port" -i "$pubkey" "${target_user}@${target_ip}" 2>/dev/null && \
      echo -e "${C_GREEN}[✓] SSH key successfully paired!${C_RESET}" || \
      echo -e "${C_YELLOW}[!] ssh-copy-id could not connect (device might be offline or password auth disabled).${C_RESET}"
  else
    cat "$pubkey" | ssh -p "$target_port" "${target_user}@${target_ip}" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" 2>/dev/null && \
      echo -e "${C_GREEN}[✓] Key copied manually.${C_RESET}" || \
      echo -e "${C_YELLOW}[!] Could not copy key over SSH.${C_RESET}"
  fi
}

# ── Custom User Tools Engine ──
omni_render_custom_tools() {
  [ -f "$CUSTOM_TOOLS_FILE" ] || return 0
  local has_entries=0
  while IFS='|' read -r t_key t_label t_cmd || [ -n "$t_key" ]; do
    t_key=$(echo "$t_key" | xargs)
    t_label=$(echo "$t_label" | xargs)
    [[ -z "$t_key" || "$t_key" =~ ^# ]] && continue
    if [ $has_entries -eq 0 ]; then
      echo ""
      echo -e "${C_BLUE}${C_BOLD}  🛠️  CUSTOM USER TOOLS & SHORTCUTS${C_RESET}"
      has_entries=1
    fi
    echo -e "  ${C_CYAN}[$t_key]${C_RESET} $t_label"
  done < "$CUSTOM_TOOLS_FILE"
}

omni_exec_custom_tool() {
  local input="$1"
  [ -f "$CUSTOM_TOOLS_FILE" ] || return 1
  while IFS='|' read -r t_key t_label t_cmd || [ -n "$t_key" ]; do
    t_key=$(echo "$t_key" | xargs)
    t_label=$(echo "$t_label" | xargs)
    t_cmd=$(echo "$t_cmd" | xargs)
    [[ -z "$t_key" || "$t_key" =~ ^# ]] && continue
    if [ "$input" = "$t_key" ]; then
      echo -e "\n${C_CYAN}─── Running: ${C_BOLD}$t_label${C_RESET} (${t_cmd})${C_CYAN} ───${C_RESET}"
      eval "$t_cmd"
      return 0
    fi
  done < "$CUSTOM_TOOLS_FILE"
  return 1
}

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
elif [ -t 0 ]; then
  omni_run_setup
  # shellcheck source=/dev/null
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
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

export OMNI_ENABLE_AI="${OMNI_ENABLE_AI:-true}"
export OMNI_ENABLE_FLEET="${OMNI_ENABLE_FLEET:-true}"
export OMNI_ENABLE_SYSTEM="${OMNI_ENABLE_SYSTEM:-true}"
export OMNI_ENABLE_CLIPBOARD="${OMNI_ENABLE_CLIPBOARD:-true}"

export OMNI_AI_ENGINE="${OMNI_AI_ENGINE:-agy}"
export OMNI_SYS_MONITOR="${OMNI_SYS_MONITOR:-htop}"
export OBSIDIAN_VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
export THIS_DEVICE_ROLE="${THIS_DEVICE_ROLE:-}"

# ── Hardware Identification ──
omni_detect_device() {
  # 1. Android Check
  if command -v getprop >/dev/null 2>&1 || [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux" ]; then
    echo "phone"
    return 0
  fi

  # 2. Hardware MAC Address Match (Authoritative across networks)
  if [ -n "${DESKTOP_MAC:-}" ] || [ -n "${LAPTOP_MAC:-}" ]; then
    local mac_list=""
    for iface_path in /sys/class/net/*; do
      [ -f "$iface_path/address" ] && mac_list="$mac_list $(cat "$iface_path/address" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    done
    if command -v ip >/dev/null 2>&1; then
      mac_list="$mac_list $(ip link 2>/dev/null | grep -i "link/ether" | awk '{print $2}' | tr '[:upper:]' '[:lower:]' || true)"
    fi
    if [ -n "${DESKTOP_MAC:-}" ] && echo "$mac_list" | grep -q "${DESKTOP_MAC,,}"; then
      echo "desktop"; return 0
    fi
    if [ -n "${LAPTOP_MAC:-}" ] && echo "$mac_list" | grep -q "${LAPTOP_MAC,,}"; then
      echo "laptop"; return 0
    fi
  fi

  # 3. Explicit Local Role from config.env
  if [ -n "${THIS_DEVICE_ROLE:-}" ]; then
    echo "$THIS_DEVICE_ROLE"
    return 0
  fi

  # 4. Tailscale / Interface IP Match
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

  # 5. Hostname Fallback
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

# ── Dynamic Terminal Geometry Helpers ──
omni_term_cols() {
  if [ -n "${COLUMNS:-}" ] && [ "$COLUMNS" -gt 0 ] 2>/dev/null; then
    echo "$COLUMNS"
    return
  fi
  local c
  c=$(tput cols 2>/dev/null) || c=80
  [ -z "$c" ] || [ "$c" -le 0 ] && c=80
  echo "$c"
}

omni_term_lines() {
  if [ -n "${LINES:-}" ] && [ "$LINES" -gt 0 ] 2>/dev/null; then
    echo "$LINES"
    return
  fi
  local l
  l=$(tput lines 2>/dev/null) || l=24
  [ -z "$l" ] || [ "$l" -le 0 ] && l=24
  echo "$l"
}

omni_hr() {
  local max="${1:-80}"
  local cols
  cols=$(omni_term_cols)
  [ "$cols" -gt "$max" ] && cols="$max"
  printf "${C_DIM}"
  printf '─%.0s' $(seq 1 "$cols")
  printf "${C_RESET}\n"
}

# ── Responsive Menu Item Formatter ──
omni_menu_item() {
  local key="$1"
  local label="$2"
  local desc="${3:-}"
  local badge="${4:-}"
  local cols
  cols=$(omni_term_cols)

  if [ "$cols" -ge 72 ] && [ -n "$desc" ]; then
    printf "  ${C_CYAN}[%s]${C_RESET} %-25s ${C_DIM}(%s)${C_RESET} %s\n" "$key" "$label" "$desc" "$badge"
  elif [ "$cols" -ge 48 ] && [ -n "$desc" ]; then
    printf "  ${C_CYAN}[%s]${C_RESET} %s ${C_DIM}(%s)${C_RESET} %s\n" "$key" "$label" "$desc" "$badge"
  else
    printf "  ${C_CYAN}[%s]${C_RESET} %s %s\n" "$key" "$label" "$badge"
  fi
}

# ── Responsive Banner Header ──
omni_render_header() {
  local dev_name="$1"
  local extra_info="${2:-}"
  local cols lines
  cols=$(omni_term_cols)
  lines=$(omni_term_lines)

  clear
  if [ "$cols" -ge 65 ] && [ "$lines" -ge 22 ]; then
    echo -e "${C_CYAN}"
    cat << "BANNER"
  ___  __  __ _   _ ___   ____ _     ___ 
 / _ \|  \/  | \ | |_ _| / ___| |   |_ _|
| | | | |\/| |  \| || | | |   | |    | | 
| |_| | |  | | |\  || | | |___| |___ | | 
 \___/|_|  |_|_| \_|___| \____|_____|___|
BANNER
    omni_hr 75
    echo -e " ${C_BOLD}OMNI System Control${C_RESET} ${C_YELLOW}${OMNI_VERSION:-v1.3.0}${C_RESET} │ ${C_BOLD}Device:${C_RESET} ${C_GREEN}${dev_name}${C_RESET} ${extra_info}"
    omni_hr 75
  elif [ "$cols" -ge 46 ]; then
    omni_hr "$cols"
    echo -e " ${C_CYAN}${C_BOLD}⚡ OMNI Control${C_RESET} ${C_YELLOW}${OMNI_VERSION:-v1.3.0}${C_RESET} │ ${C_BOLD}Device:${C_RESET} ${C_GREEN}${dev_name}${C_RESET}"
    if [ -n "$extra_info" ]; then
      local clean_extra="${extra_info#│ }"
      echo -e " ${C_DIM}Status:${C_RESET} ${clean_extra}"
    fi
    omni_hr "$cols"
  else
    # Ultra-compact view for mobile/narrow terminals (cols < 46)
    echo -e "${C_CYAN}${C_BOLD}⚡ OMNI ${C_YELLOW}${OMNI_VERSION:-v1.3.0}${C_RESET} │ ${C_GREEN}${dev_name}${C_RESET}"
    if [ -n "$extra_info" ]; then
      local clean_extra="${extra_info#│ }"
      echo -e " ${C_DIM}${clean_extra}${C_RESET}"
    fi
    omni_hr "$cols"
  fi
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
      echo -e "${C_CYAN}[1/2] Syncing Omni suite from Desktop (${DESKTOP_IP})...${C_RESET}"
      mkdir -p "$HOME/bin" "$HOME/.config/omni"
      if [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
        if scp "${DESKTOP_USER}@${DESKTOP_IP}:~/dotfiles/bin/omni*" "$HOME/bin/" 2>/dev/null || \
           scp "${DESKTOP_USER}@${DESKTOP_IP}:~/phone-hub/bin/omni*" "$HOME/bin/" 2>/dev/null; then
          chmod +x "$HOME/bin/omni"*
          scp "${DESKTOP_USER}@${DESKTOP_IP}:~/.config/omni/custom_tools.conf" "$HOME/.config/omni/" 2>/dev/null || true
          echo -e "${C_GREEN}[✓] Omni suite updated from Desktop!${C_RESET}"
        else
          echo -e "${C_RED}[!] Download failed. Check SSH permissions to Desktop.${C_RESET}"
        fi
      else
        echo -e "${C_RED}[!] Desktop ($DESKTOP_IP) is unreachable. Ensure Tailscale is connected.${C_RESET}"
      fi

      echo -e "${C_CYAN}[2/2] Updating phone shell config...${C_RESET}"
      if command -v sync-down >/dev/null 2>&1; then
        sync-down 2>/dev/null || true
      fi
      ;;
  esac

  echo -e "\n${C_GREEN}${C_BOLD}[✓] Omni CLI is fully up to date!${C_RESET}"
}

# ── Unified Git & Peer Sync Submenu ──
omni_sync_menu() {
  local dev
  dev=$(omni_detect_device)

  echo -e "\n${C_CYAN}${C_BOLD}🔄 OMNI PUSH & PULL SYNC (${dev})${C_RESET}"
  echo -e "  ${C_CYAN}[1]${C_RESET} ⬇️  Git Pull   (Fetch latest updates from GitHub)"
  echo -e "  ${C_CYAN}[2]${C_RESET} ⬆️  Git Push   (Commit local dotfiles changes & push to GitHub)"

  case "$dev" in
    phone)
      echo -e "  ${C_CYAN}[3]${C_RESET} 📥 Pull from Desktop (SCP ~/bin & config from Desktop)"
      echo -e "  ${C_CYAN}[4]${C_RESET} 📤 Push to Desktop   (SCP phone scripts to Desktop ~/phone-hub/bin)"
      ;;
    laptop)
      echo -e "  ${C_CYAN}[3]${C_RESET} 📥 Pull from Desktop (SCP scripts/configs from Desktop)"
      echo -e "  ${C_CYAN}[4]${C_RESET} 📤 Push to Desktop   (SCP local scripts to Desktop)"
      echo -e "  ${C_CYAN}[5]${C_RESET} 📱 Push to Phone     (SCP scripts to Phone ~/bin)"
      ;;
    *)
      echo -e "  ${C_CYAN}[3]${C_RESET} 📱 Push to Phone     (SCP scripts to Phone ~/bin)"
      echo -e "  ${C_CYAN}[4]${C_RESET} 💻 Push to Laptop    (SCP scripts to Laptop ~/.local/bin)"
      echo -e "  ${C_CYAN}[5]${C_RESET} 📥 Pull from Phone   (SCP Phone ~/bin to Desktop ~/phone-hub/bin)"
      ;;
  esac
  echo -e "  ${C_DIM}[Enter / q] Cancel back to menu${C_RESET}"

  read -rsn1 -p "Select sync action: " sact
  echo ""

  case "$sact" in
    ""|q|Q) return 0 ;;
    1)
      echo -e "${C_CYAN}[*] Pulling latest git updates...${C_RESET}"
      local gdir="$HOME/dotfiles"
      [ -d "$gdir/.git" ] || gdir="$(dirname "$SCRIPT_DIR")"
      if [ -d "$gdir/.git" ]; then
        git -C "$gdir" pull --rebase origin main && \
          echo -e "${C_GREEN}[✓] Git repository updated successfully!${C_RESET}" || \
          echo -e "${C_RED}[!] Git pull failed.${C_RESET}"
      else
        echo -e "${C_YELLOW}[!] No git repository found at $gdir.${C_RESET}"
      fi
      ;;
    2)
      echo -e "${C_CYAN}[*] Pushing local changes to Git...${C_RESET}"
      local gdir="$HOME/dotfiles"
      [ -d "$gdir/.git" ] || gdir="$(dirname "$SCRIPT_DIR")"
      if [ -d "$gdir/.git" ]; then
        read -r -p "Commit message [default: 'omni: sync dotfiles']: " cmsg
        cmsg="${cmsg:-omni: sync dotfiles}"
        git -C "$gdir" add -A && \
        git -C "$gdir" commit -m "$cmsg" 2>/dev/null || true
        git -C "$gdir" push origin main && \
          echo -e "${C_GREEN}[✓] Successfully pushed to origin/main!${C_RESET}" || \
          echo -e "${C_RED}[!] Git push failed.${C_RESET}"
      else
        echo -e "${C_YELLOW}[!] No git repository found at $gdir.${C_RESET}"
      fi
      ;;
    3)
      if [ "$dev" = "phone" ]; then
        echo -e "${C_CYAN}[*] Pulling latest Omni suite from Desktop (${DESKTOP_IP})...${C_RESET}"
        mkdir -p "$HOME/bin" "$HOME/.config/omni"
        if [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
          if scp "${DESKTOP_USER}@${DESKTOP_IP}:~/dotfiles/bin/omni*" "$HOME/bin/" 2>/dev/null || \
             scp "${DESKTOP_USER}@${DESKTOP_IP}:~/phone-hub/bin/omni*" "$HOME/bin/" 2>/dev/null; then
            chmod +x "$HOME/bin/omni"*
            scp "${DESKTOP_USER}@${DESKTOP_IP}:~/.config/omni/custom_tools.conf" "$HOME/.config/omni/" 2>/dev/null || true
            echo -e "${C_GREEN}[✓] Pulled latest Omni suite from Desktop!${C_RESET}"
          else
            echo -e "${C_RED}[!] Pull failed. Check SSH permissions to Desktop.${C_RESET}"
          fi
        else
          echo -e "${C_RED}[!] Desktop ($DESKTOP_IP) is unreachable.${C_RESET}"
        fi
      elif [ "$dev" = "laptop" ]; then
        echo -e "${C_CYAN}[*] Pulling latest Omni scripts from Desktop (${DESKTOP_IP})...${C_RESET}"
        mkdir -p "$HOME/.local/bin"
        if [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
          scp "${DESKTOP_USER}@${DESKTOP_IP}:~/dotfiles/bin/omni*" "$HOME/.local/bin/" && \
            chmod +x "$HOME/.local/bin/omni"* && \
            echo -e "${C_GREEN}[✓] Pulled from Desktop!${C_RESET}" || echo -e "${C_RED}[!] Pull failed.${C_RESET}"
        else
          echo -e "${C_RED}[!] Desktop unreachable.${C_RESET}"
        fi
      else
        # Desktop: Push to phone
        echo -e "${C_CYAN}[*] Pushing Omni suite to Phone (${PHONE_IP})...${C_RESET}"
        if [ -n "$PHONE_IP" ] && omni_is_online "$PHONE_IP"; then
          scp -P "$PHONE_PORT" -r "$HOME/dotfiles/bin"/omni* "${PHONE_USER}@${PHONE_IP}:~/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pushed to Phone successfully!${C_RESET}" || \
            echo -e "${C_RED}[!] Push to phone failed.${C_RESET}"
        else
          echo -e "${C_YELLOW}[!] Phone ($PHONE_IP) is offline.${C_RESET}"
        fi
      fi
      ;;
    4)
      if [ "$dev" = "phone" ]; then
        echo -e "${C_CYAN}[*] Pushing phone scripts to Desktop (${DESKTOP_IP})...${C_RESET}"
        if [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
          ssh "${DESKTOP_USER}@${DESKTOP_IP}" "mkdir -p ~/phone-hub/bin" 2>/dev/null
          scp "$HOME/bin"/omni* "${DESKTOP_USER}@${DESKTOP_IP}:~/phone-hub/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pushed to Desktop ~/phone-hub/bin!${C_RESET}" || \
            echo -e "${C_RED}[!] Push failed.${C_RESET}"
        else
          echo -e "${C_RED}[!] Desktop unreachable.${C_RESET}"
        fi
      elif [ "$dev" = "laptop" ]; then
        echo -e "${C_CYAN}[*] Pushing laptop scripts to Desktop (${DESKTOP_IP})...${C_RESET}"
        if [ -n "$DESKTOP_IP" ] && omni_is_online "$DESKTOP_IP"; then
          scp "$HOME/.local/bin"/omni* "${DESKTOP_USER}@${DESKTOP_IP}:~/dotfiles/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pushed to Desktop!${C_RESET}" || \
            echo -e "${C_RED}[!] Push failed.${C_RESET}"
        else
          echo -e "${C_RED}[!] Desktop unreachable.${C_RESET}"
        fi
      else
        # Desktop: Push to laptop
        echo -e "${C_CYAN}[*] Pushing Omni suite to Laptop (${LAPTOP_IP})...${C_RESET}"
        if [ -n "$LAPTOP_IP" ] && omni_is_online "$LAPTOP_IP"; then
          scp -r "$HOME/dotfiles/bin"/omni* "${LAPTOP_USER}@${LAPTOP_IP}:~/.local/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pushed to Laptop!${C_RESET}" || \
            echo -e "${C_RED}[!] Push failed.${C_RESET}"
        else
          echo -e "${C_YELLOW}[!] Laptop ($LAPTOP_IP) is offline.${C_RESET}"
        fi
      fi
      ;;
    5)
      if [ "$dev" = "laptop" ]; then
        echo -e "${C_CYAN}[*] Pushing to Phone from Laptop (${PHONE_IP})...${C_RESET}"
        if [ -n "$PHONE_IP" ] && omni_is_online "$PHONE_IP"; then
          scp -P "$PHONE_PORT" -r "$HOME/.local/bin"/omni* "${PHONE_USER}@${PHONE_IP}:~/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pushed to Phone!${C_RESET}" || \
            echo -e "${C_RED}[!] Push failed.${C_RESET}"
        else
          echo -e "${C_YELLOW}[!] Phone offline.${C_RESET}"
        fi
      elif [ "$dev" = "desktop" ]; then
        echo -e "${C_CYAN}[*] Pulling Phone bin to Desktop ~/phone-hub/bin...${C_RESET}"
        if [ -n "$PHONE_IP" ] && omni_is_online "$PHONE_IP"; then
          mkdir -p "$HOME/phone-hub/bin"
          scp -P "$PHONE_PORT" "${PHONE_USER}@${PHONE_IP}:~/bin/omni*" "$HOME/phone-hub/bin/" 2>/dev/null && \
            echo -e "${C_GREEN}[✓] Pulled phone scripts to ~/phone-hub/bin!${C_RESET}" || \
            echo -e "${C_RED}[!] Pull failed.${C_RESET}"
        else
          echo -e "${C_YELLOW}[!] Phone offline.${C_RESET}"
        fi
      fi
      ;;
    *)
      echo -e "${C_YELLOW}[!] Unknown choice.${C_RESET}"
      ;;
  esac
}
