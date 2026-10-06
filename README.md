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
3. **HexaCore Workstation Manager (`hexacore/`)**:
   - `workflow-hexacore` execution binary
   - `hexacore` CLI shortcut
   - Hyprland keybinding configuration (`SUPER + ALT + H`)
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
