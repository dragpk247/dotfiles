-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Productivity Keybindings
o.bind("SUPER + SHIFT + R", "Omarchy AI Gateway Dashboard", "xdg-open http://localhost:8000/dashboard")
o.bind("SUPER + D", "AI SDLC Development Hub", "omarchy-sdlc-menu")
o.rebind("SUPER + SHIFT + A", "Aider (Desktop Free Qwen)", "kitty --class aider-float -e bash -ic aq")
o.rebind("SUPER + ALT + A", "Aider (Claude Haiku)", "kitty --class aider-float -e bash -ic ah")
o.bind("SUPER + GRAVE", "Dropdown scratchpad terminal", "toggle-dropdown-terminal")
o.rebind("SUPER + SHIFT + T", "Extract text from screen (OCR)", "omarchy capture text")
hl.unbind("SUPER + K")
o.bind("SUPER + U", "Dizzie System Updates", { panel = "dizziee.system-updates" })
o.bind("SUPER + ALT + P", "Fuzzy project workspace switcher", "project-switcher")
o.bind("SUPER + ALT + W", "Dev Workflows & Tool Stacks", "omarchy-workflow-menu")
o.bind("SUPER + ALT + H", "Launch HexaCore 6-Workspace Workflow", "workflow-hexacore")

-- AI Agent Shortcuts
o.rebind("SUPER + A", "Antigravity CLI", "omarchy-launch-or-focus agy 'kitty --class agy --title agy -e agy'")
o.bind("SUPER + SHIFT + H", "Hermes Agent", "omarchy-launch-or-focus hermes 'kitty --title hermes -e hermes'")

-- ASUS ROG Flow X13 Laptop Specific Controls
local hostname = (io.popen("hostname 2>/dev/null"):read("*l") or ""):lower()
if hostname:find("laptop") then
  -- Battery limit toggle & Keyboard Backlight Sync
  o.bind("SUPER + ALT + B", "Toggle battery limit (80% / 100%)", "asus-battery-toggle")
  o.rebind("SUPER + ALT + K", "Toggle keyboard backlight", "asus-kbd-sync toggle", { locked = true })
  o.bind("SUPER + ALT + R", "Cycle ROG fan & performance profile", "asus-profile-toggle")
  o.bind("SUPER + ALT + G", "Toggle GPU (Integrated / Hybrid) & power profile", "gpu-profile-switch toggle")
  o.bind("SUPER + ALT + T", "Toggle tablet / tent mode", "asus-tablet-mode")

  -- Screen Orientation (Tent / Tablet)
  o.bind("SUPER + ALT + UP", "Screen orientation: Normal", "asus-rotate normal")
  o.bind("SUPER + ALT + DOWN", "Screen orientation: Inverted (Tent mode)", "asus-rotate inverted")
  o.bind("SUPER + ALT + RIGHT", "Screen orientation: 90° portrait", "asus-rotate right")
  o.bind("SUPER + ALT + LEFT", "Screen orientation: 270° portrait", "asus-rotate left")

  -- ASUS ROG Hardware Media Controls (M4 & Chassis Volume Keys)
  o.bind("XF86Launch1", "Play / Pause media", { ipc = "media.playPause" }, { locked = true })
  o.bind("XF86Tools", "Play / Pause media", { ipc = "media.playPause" }, { locked = true })
  o.bind("CTRL + XF86AudioRaiseVolume", "Next track", { ipc = "media.next" }, { locked = true })
  o.bind("CTRL + XF86AudioLowerVolume", "Previous track", { ipc = "media.previous" }, { locked = true })
end

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
