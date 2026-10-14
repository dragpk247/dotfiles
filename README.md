# 🌌 Omarchy Dotfiles

Automated dotfile management for **[Omarchy](https://omarchy.org/)** shell plugins, layouts, keybindings, and the **HexaCore** workstation manager.

---

## 🚀 Installing on a New Machine (Fresh Setup)

Follow these steps to replicate your entire Omarchy environment, plugins, bar widgets, shortcuts, and helper tools on a new desktop or laptop:

### 1. Prerequisites
Ensure Git, Python 3, and GitHub CLI (`gh`) are installed:
```bash
sudo pacman -S git python github-cli  # Arch / Omarchy
```
Authenticate with GitHub (so private repos and forks can be cloned):
```bash
gh auth login
```

### 2. Clone Dotfiles
Clone your dotfiles repository into `~/dotfiles`:
```bash
git clone https://github.com/dragpk247/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Run the Installer
Run the root install script:
```bash
./install.sh
```

#### What `install.sh` automatically does:
- 🔌 **Restores Upstream Plugins**: Clones all registered Git plugins into `~/.config/omarchy/plugins/` (including your customized [`omarchy-github`](https://github.com/dragpk247/omarchy-github) fork, Lacquer, Argus, NextHop, etc.).
- 🧩 **Restores Custom Plugins**: Restores `jpi.menu`, `user.dev-workflows`, `user.agents-control`, `user.apps-menu`, `user.process-cleaner`, etc.
- ⚙️ **Restores Shell Configuration**: Restores `~/.config/omarchy/shell.json` (with automatic timestamped backups of existing configs).
- ⌨️ **Restores Hyprland Bindings & Shortcuts**: Restores `bindings.lua`, `hyprland.lua`, and `autostart.lua` into `~/.config/hypr/`.
- 🛠️ **Installs Helper Scripts**: Copies all shortcut binaries (`git-flow-*`, `asus-*`, `toggle-dropdown-terminal`, `project-switcher`, etc.) into `~/.local/bin/` with executable permissions.
- 🏢 **Installs HexaCore**: Installs `workflow-hexacore` and sets up the `SUPER + ALT + H` binding.
- 🔗 **Links CLI**: Symlinks `omarchy-dotfiles` into `~/.local/bin/omarchy-dotfiles`.

### 4. (Optional) Laptop-Specific Tools & Plugins
If you are setting up on a **laptop** with hybrid graphics or ASUS controls, install your laptop suite:
```bash
git clone https://github.com/dragpk247/omarchy-laptop-tools-and-plugins.git ~/Projects/omarchy-laptop-tools-and-plugins
cd ~/Projects/omarchy-laptop-tools-and-plugins
./install.sh
```
*(On desktops, you can skip this step!)*

### 5. Reload Shell
Reload Hyprland and Omarchy Shell to apply all widgets:
```bash
hyprctl reload
# Or restart Omarchy shell
omarchy-shell --restart 2>/dev/null || true
```

---

## 📦 What's Tracked

1. **Omarchy Shell Plugins (`omarchy/plugins/`)**:
   - **Upstream & Forked Plugins** (tracked via `plugins.json` with git URLs and branches):
     - `robzolkos.github` (Fork: `https://github.com/dragpk247/omarchy-github.git` with custom quick actions and 50-repo limit)
     - `io.github.deunnis.lacquer`
     - `io.github.diegopluna.argus`
     - `io.github.x3me.nexthop`
     - `dizziee.auto-wallpaper`
     - `dizziee.cline-model-usage`
     - `dizziee.system-updates`
     - `ucmz851.omasecurity`
   - **Custom Plugins** (full source tracked in `omarchy/plugins/custom/`):
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
   - Status bar widget ordering (left, center, right)
   - Enabled and disabled plugins
   - Idle lock, battery, and screensaver thresholds
3. **Omarchy Shortcuts & Hyprland Configs (`hypr/`, `omarchy/extensions/`, `shortcuts/`)**:
   - Hyprland keybindings ([`hypr/bindings.lua`](hypr/bindings.lua)):
     - Dropdown scratchpad terminal (`SUPER + GRAVE`)
     - Battery limit toggle (`SUPER + ALT + B`)
     - Keyboard backlight toggle (`SUPER + ALT + K`)
     - ROG fan & power profile cycle (`SUPER + ALT + R`)
     - GPU profile switch (`SUPER + ALT + G`)
     - Fuzzy project workspace switcher (`SUPER + ALT + P`)
     - Tablet / tent mode toggle (`SUPER + ALT + T`)
     - Dev Workflows menu (`SUPER + ALT + W`)
     - HexaCore 6-workspace deployment (`SUPER + ALT + H`)
     - AI Agent focus/launcher (`SUPER + A`, `SUPER + SHIFT + H`)
   - Shortcut helper scripts ([`shortcuts/scripts/`](shortcuts/scripts/)):
     - `git-flow-contribute`, `git-flow-pr`, `git-flow-switch`
     - `toggle-dropdown-terminal`, `asus-battery-toggle`, `asus-kbd-sync`, `asus-profile-toggle`, `gpu-profile-switch`, `project-switcher`, `asus-tablet-mode`, `omarchy-workflow-menu`, `asus-rotate`, `asus-agent-menu`, `asus-kbd-menu`
4. **HexaCore Workstation Manager (`hexacore/`)**:
   - `workflow-hexacore` execution binary and `hexacore` CLI alias.

---

## 🔄 Daily Workflow & Syncing

### Updating / Syncing Changes
Whenever you install new plugins, modify widgets, or add scripts on any machine:
```bash
omarchy-dotfiles sync --push
```
Or with a custom commit message:
```bash
omarchy-dotfiles sync --push -m "feat: added new custom widget"
```

### Pulling Updates on Other Machines
To update your desktop or laptop with changes pushed from another machine:
```bash
cd ~/dotfiles
git pull
omarchy-dotfiles install
```

### Checking Status
```bash
omarchy-dotfiles status
```
Shows currently registered upstream and custom plugins along with repository status.
