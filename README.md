# 🌌 Omarchy Dotfiles

Automated dotfile management for **[Omarchy](https://omarchy.org/)** shell plugins, layouts, and the **HexaCore** workstation manager.

---

## 📦 What's Tracked

1. **Omarchy Shell Plugins (`omarchy/plugins/`)**:
   - **Upstream & Forked Plugins** (tracked via `plugins.json` with git URLs and pinned commits):
     - `robzolkos.github` (Custom fork with Git workflow actions & 50-repo limit)
     - `io.github.deunnis.lacquer`
     - `io.github.diegopluna.argus`
     - `io.github.x3me.nexthop`
     - `dizziee.auto-wallpaper`
     - `dizziee.cline-model-usage`
     - `dizziee.system-updates`
     - `ucmz851.omasecurity`
   - **Custom & Local Plugins** (full source tracked in `omarchy/plugins/custom/`):
     - `jpi.menu` (Customized Omarchy launcher menu)
     - `jpi.monitor` (Customized display brightness & controls)
     - `jpi.power` (Power & battery widget)
     - `user.agents-control` (AI agents switcher & controls)
     - `user.apps-menu` (Applications menu widget)
     - `user.dev-workflows` (Development workflows quick launcher)
     - `user.gpu-switcher` (Modular GPU switcher)
     - `user.kbd-backlight` (Keyboard backlight controls)
     - `user.process-cleaner` (Process manager & cleaner)
2. **Omarchy Shell Config (`omarchy/shell.json`)**:
   - Bar status layout (left, center, right widgets)
   - Enabled and disabled plugins
   - Idle lock and screensaver thresholds
3. **Omarchy Shortcuts & Hyprland Configs (`hypr/`, `omarchy/extensions/`, `shortcuts/`)**:
   - Hyprland keybindings ([`hypr/bindings.lua`](hypr/bindings.lua)):
     - Dropdown scratchpad terminal (`SUPER + GRAVE`)
     - Screen text OCR capture (`SUPER + SHIFT + T`)
     - Battery limit toggle (`SUPER + ALT + B`)
     - Keyboard backlight toggle (`SUPER + ALT + K`)
     - ROG fan & power profile cycle (`SUPER + ALT + R`)
     - GPU profile switch (`SUPER + ALT + G`)
     - Fuzzy project workspace switcher (`SUPER + ALT + P`)
     - Tablet / tent mode toggle (`SUPER + ALT + T`)
     - Dev Workflows menu (`SUPER + ALT + W`)
     - HexaCore 6-workspace deployment (`SUPER + ALT + H`)
     - Screen orientation shortcuts (`SUPER + ALT + Arrows`)
     - AI Agent focus/launcher (`SUPER + A`, `SUPER + SHIFT + H`)
   - Hyprland window rules & autostart ([`hypr/hyprland.lua`](hypr/hyprland.lua), [`hypr/autostart.lua`](hypr/autostart.lua))
   - Omarchy menu extensions & actions ([`omarchy/extensions/omarchy-menu.jsonc`](omarchy/extensions/omarchy-menu.jsonc))
   - Shortcut helper scripts ([`shortcuts/scripts/`](shortcuts/scripts/)):
     - `git-flow-contribute`, `git-flow-pr`, `git-flow-switch`
     - `toggle-dropdown-terminal`, `asus-battery-toggle`, `asus-kbd-sync`, `asus-profile-toggle`, `gpu-profile-switch`, `project-switcher`, `asus-tablet-mode`, `omarchy-workflow-menu`, `asus-rotate`, `asus-agent-menu`, `asus-kbd-menu`
4. **HexaCore Workstation Manager (`hexacore/`)**:
   - `workflow-hexacore` execution binary
   - `hexacore` CLI shortcut
   - Standalone installation script

---

## 🚀 Usage

### 🔄 Updating / Syncing When You Add More Plugins

Whenever you install new plugins, modify widgets, or change shell settings, run:

```bash
omarchy-dotfiles sync
```

Or sync and immediately push to GitHub:
```bash
omarchy-dotfiles sync --push
```

### 🔍 Checking Status

```bash
omarchy-dotfiles status
```

Shows currently registered upstream and custom plugins along with repository status.

### 📥 Restoring / Installing on a New Machine

To restore everything onto a fresh Omarchy system:

```bash
git clone https://github.com/dragpk247/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

> **Laptop Users**: To install hybrid graphics and ASUS ROG battery/power tools on a laptop, also run:
> ```bash
> git clone https://github.com/dragpk247/omarchy-laptop-tools-and-plugins.git ~/Projects/omarchy-laptop-tools-and-plugins
> cd ~/Projects/omarchy-laptop-tools-and-plugins && ./install.sh
> ```
