# 🌌 Omarchy Dotfiles

Automated dotfile management for **[Omarchy](https://omarchy.org/)** shell plugins, layouts, and the **HexaCore** workstation manager.

---

## 📦 What's Tracked

1. **Omarchy Shell Plugins (`omarchy/plugins/`)**:
   - **Upstream Plugins** (tracked via `plugins.json` with git URLs and pinned commits):
     - `dizziee.auto-wallpaper`
     - `dizziee.cline-model-usage`
     - `dizziee.system-updates`
     - `io.github.deunnis.lacquer`
     - `io.github.diegopluna.argus`
     - `io.github.x3me.nexthop`
     - `robzolkos.github`
     - `ucmz851.omasecurity`
   - **Custom & Local Plugins** (full source tracked in `omarchy/plugins/custom/`):
     - `jpi.menu` (Customized Omarchy launcher menu)
     - `jpi.monitor` (Customized laptop display brightness & controls)
     - `user.agents-control` (AI agents switcher & controls)
     - `user.apps-menu` (Applications menu widget)
     - `user.dev-workflows` (Development workflows quick launcher)
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

Or from the dotfiles directory:
```bash
./sync.sh
```

**Or simply ask Antigravity:**
> *"Update my dotfiles with the new plugins."*

The sync engine will:
1. Scan `~/.config/omarchy/plugins/` for any new or modified plugins.
2. Auto-detect whether a plugin is from an upstream Git repo or custom-built.
3. Update `plugins.json` manifest and copy new custom plugin sources.
4. Sync `~/.config/omarchy/shell.json` and HexaCore scripts.
5. Create a descriptive Git commit in `~/dotfiles`.

### 🔍 Checking Status

```bash
omarchy-dotfiles status
```

Shows currently registered upstream and custom plugins along with repository status.

### 📥 Restoring / Installing on a New Machine

To install or restore everything onto a fresh Omarchy system:

```bash
cd ~/dotfiles
./install.sh
```

---

## 🛠️ Optional: Link to GitHub

To push your dotfiles to GitHub:

```bash
cd ~/dotfiles
gh repo create dotfiles --private --source=. --remote=origin --push
```
