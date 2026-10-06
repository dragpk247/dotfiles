# 💎 HexaCore Workstation Layout for Omarchy

An automated 6-workspace development and telemetry workstation layout manager designed for **[Omarchy](https://omarchy.org/) (Arch Linux + Hyprland)**.

Optimized for power efficiency, multitasking, and battery preservation on mobile developer machines (such as the ASUS ROG Flow X13).

---

## ⚡ Why HexaCore?

On Wayland / Hyprland, **unviewed workspaces pause background window rendering**. Spanning your workflow across dedicated workspaces gives you instant full-screen distraction-free contexts while drastically slashing background GPU and CPU frame-rendering cycles.

### 🗺️ Workspace Allocations

| Workspace | Application | Role | Hotkey |
| :---: | :--- | :--- | :---: |
| **1** | **Antigravity CLI (`agy`)** | Primary AI coding & shell workspace | <kbd>Super</kbd> + <kbd>1</kbd> |
| **2** | **Firefox** | Web research, documentation, session auto-restore | <kbd>Super</kbd> + <kbd>2</kbd> |
| **3** | **Spotify** | Music & audio playback | <kbd>Super</kbd> + <kbd>3</kbd> |
| **4** | **`btop`** | CPU core frequency, memory, and task monitoring | <kbd>Super</kbd> + <kbd>4</kbd> |
| **5** | **`nvtop`** | GPU thermals, VRAM usage, and power draw | <kbd>Super</kbd> + <kbd>5</kbd> |
| **6** | **Mission Center** | System performance GUI overview | <kbd>Super</kbd> + <kbd>6</kbd> |

---

## 🔒 Dynamic Cold-Boot Synchronization

Unlike static Hyprland window rules (`windowrule = workspace 2, class:firefox`), which hijack normal window creation whenever you launch apps casually throughout the day, HexaCore uses **dynamic launch synchronization**:

1. Switches to each designated workspace using Omarchy's focus dispatcher:
   ```bash
   hyprctl dispatch "hl.dsp.focus({ workspace = '<N>' })"
   ```
2. Launches the application in the background.
3. Holds workspace focus and dynamically polls `hyprctl clients` until the window is verified to have spawned on that workspace before proceeding.
4. Returns user focus back to **Workspace 1** once all windows are docked.

This guarantees zero workspace bleed even during cold reboots when heavy apps take several seconds to open.

---

## 🚀 Installation

```bash
git clone https://github.com/dragpk247/omarchy-hexacore.git
cd omarchy-hexacore
./install.sh
```

The installer will:
1. Install `workflow-hexacore` and alias `hexacore` to `~/.local/bin/`.
2. Register the default keybinding (<kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>H</kbd>) in `~/.config/hypr/bindings.lua`.
3. Reload Hyprland configuration.

---

## ⌨️ Usage

- **Via Hotkey**: Press <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>H</kbd>
- **Via Terminal**: Run `hexacore` or `workflow-hexacore`

---

## 📄 License

MIT License. Designed with care for Omarchy & Hyprland users.
