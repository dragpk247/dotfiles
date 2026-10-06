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
o.bind("SUPER + GRAVE", "Dropdown scratchpad terminal", "toggle-dropdown-terminal")
o.bind("SUPER + SHIFT + T", "Extract text from screen (OCR)", "omarchy capture text")
o.bind("SUPER + ALT + B", "Toggle battery limit (80% / 100%)", "asus-battery-toggle")
hl.unbind("SUPER + K")
hl.unbind("SUPER + ALT + K")
o.bind("SUPER + ALT + K", "Toggle keyboard backlight", "/home/jpi/.local/bin/asus-kbd-sync toggle", { locked = true })
o.bind("SUPER + ALT + R", "Cycle ROG fan & performance profile", "asus-profile-toggle")
o.bind("SUPER + ALT + G", "Toggle GPU (Integrated / Hybrid) & power profile", "gpu-profile-switch toggle")
o.bind("SUPER + ALT + P", "Fuzzy project workspace switcher", "project-switcher")
o.bind("SUPER + ALT + T", "Toggle tablet / tent mode", "asus-tablet-mode")
o.bind("SUPER + ALT + W", "Dev Workflows & Tool Stacks", "omarchy-workflow-menu")
o.bind("SUPER + ALT + H", "Launch HexaCore 6-Workspace Workflow", "workflow-hexacore")

-- Screen Orientation Shortcuts
o.bind("SUPER + ALT + UP", "Screen orientation: Normal", "asus-rotate normal")
o.bind("SUPER + ALT + DOWN", "Screen orientation: Inverted (Tent mode)", "asus-rotate inverted")
o.bind("SUPER + ALT + RIGHT", "Screen orientation: 90° portrait", "asus-rotate right")
o.bind("SUPER + ALT + LEFT", "Screen orientation: 270° portrait", "asus-rotate left")

-- AI Agent Shortcuts
o.bind("SUPER + A", "Antigravity CLI", "omarchy-launch-or-focus agy 'kitty --class agy --title agy -e agy'")
o.bind("SUPER + SHIFT + H", "Hermes Agent", "omarchy-launch-or-focus hermes 'kitty --title hermes -e hermes'")
