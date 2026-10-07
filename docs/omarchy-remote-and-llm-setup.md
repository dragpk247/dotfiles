# Omarchy Setup & Reference Guide

This document preserves the setup, configuration details, and commands discussed during our session on machine `omarchy` (NVIDIA RTX 5070 Ti, Arch Linux / Omarchy).

---

## 1. Dotfiles Setup

- **GitHub Repository**: [dragpk247/dotfiles](https://github.com/dragpk247/dotfiles)
- **Local Directory**: `~/dotfiles`
- **Installed Components**:
  - **8 Upstream Plugins** (`~/.config/omarchy/plugins/`):
    - `dizziee.auto-wallpaper`, `dizziee.cline-model-usage`, `dizziee.system-updates`
    - `io.github.deunnis.lacquer`, `io.github.diegopluna.argus`, `io.github.x3me.nexthop`
    - `robzolkos.github`, `ucmz851.omasecurity`
  - **7 Custom Plugins**:
    - `jpi.menu`, `jpi.monitor`, `user.agents-control`, `user.apps-menu`, `user.dev-workflows`, `user.kbd-backlight`, `user.process-cleaner`
  - **Shell Configuration**: Tracked `shell.json` restored (previous version backed up in `~/.config/omarchy/`).
  - **HexaCore Workstation Manager**:
    - Binaries in `~/.local/bin/workflow-hexacore` and alias `~/.local/bin/hexacore`
    - Keybinding: `SUPER + ALT + H` in `~/.config/hypr/bindings.lua`
  - **CLI Tool**: `omarchy-dotfiles` linked to `~/.local/bin/omarchy-dotfiles`

### Useful Dotfiles Commands:
```bash
omarchy-dotfiles status   # View plugin and git status
omarchy-dotfiles sync     # Auto-sync changes/new plugins back to dotfiles repo
~/dotfiles/install.sh     # Re-run full installation
```

---

## 2. Remote Desktop Control (Laptop -> Desktop via Sunshine & Moonlight)

Ultra-low latency remote desktop streaming with RTX 5070 Ti hardware encoding.

### On this Desktop (`omarchy` / `192.168.15.79`):
```bash
# 1. Install Sunshine
sudo pacman -S sunshine

# 2. Add user to input group for mouse/keyboard emulation
sudo usermod -aG input $USER

# 3. Allow Sunshine through UFW firewall
sudo ufw allow 47984:48010/tcp
sudo ufw allow 47984:48010/udp

# 4. Enable and start Sunshine user service
systemctl --user enable --now sunshine
```
- Open [https://localhost:47990](https://localhost:47990) in Firefox to create admin credentials and enter the 4-digit PIN when pairing.

### On your Laptop:
```bash
# Install Moonlight client (Arch / Omarchy)
sudo pacman -S moonlight-qt
# (or flatpak install flathub com.moonlight_stream.Moonlight)
```
- Open Moonlight, discover/add `omarchy` (`192.168.15.79`), type the PIN in the Sunshine web interface, and click **Desktop** to start streaming.

---

## 3. Remote LLM Access via Hotspot (Desktop RTX 5070 Ti -> Laptop)

### Desktop Status & Local Models:
Ollama service (`~/.config/systemd/user/ollama.service`) is configured to listen on all interfaces (`0.0.0.0:11434`) with `OLLAMA_ORIGINS=*`.
All models are fully downloaded and accelerated by your NVIDIA RTX 5070 Ti (16 GB GDDR7):

| Model | Size | Best For |
|---|---|---|
| `qwen2.5-coder:14b` | 9.0 GB | Coding, agent workflows, refactoring |
| `deepseek-r1:14b` | 9.0 GB | Deep mathematical & step-by-step reasoning |
| `phi4:14b` | 9.1 GB | High-level logic, complex reasoning, science |
| `llama3.2:3b` | 2.0 GB | Ultra-fast responses (ideal on mobile hotspot/battery) |
| `mistral-nemo:12b` | 7.1 GB | General conversation, drafting, summaries |
| `llama3.1:8b` | 4.9 GB | Balanced general assistant |
| `nomic-embed-text` | 274 MB | Semantic search, embeddings & RAG in Open WebUI |

### Step A: Connect across Hotspot via Tailscale (Mesh VPN)
When your laptop is on a mobile hotspot and desktop is at home behind NAT, Tailscale provides a direct, encrypted WireGuard tunnel without port forwarding.

**On Desktop:**
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**On Laptop:**
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```
*(Sign into the same account on both machines).*

**On Desktop Firewall (`ufw`):**
```bash
sudo ufw allow in on tailscale0 to any port 11434 proto tcp
sudo ufw allow in on tailscale0 to any port 8080 proto tcp
```

---

### Step B: Run Web UI (Open WebUI) on Desktop
```bash
sudo docker run -d --network=host -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```
- Open on laptop browser: `http://omarchy:8080` (or `http://<desktop-tailscale-ip>:8080`).

---

### Step C: Use LLMs via CLI & Coding Agents on Laptop

#### 1. Ollama CLI from Laptop:
```bash
export OLLAMA_HOST="http://omarchy:11434"
ollama list
ollama run qwen2.5-coder:14b
```
*(Tip: Add `export OLLAMA_HOST="http://omarchy:11434"` to `~/.bashrc` on your laptop).*

#### 2. In Coding Agents (Aider, Claude Code, Continue, OpenCode):
- **API Base**: `http://omarchy:11434/v1`
- **API Key**: `ollama` (or any string)
- **Model**: `openai/qwen2.5-coder:14b` or `openai/deepseek-r1:14b`

Example using Aider:
```bash
aider --openai-api-base http://omarchy:11434/v1 --openai-api-key ollama --model openai/qwen2.5-coder:14b
```
