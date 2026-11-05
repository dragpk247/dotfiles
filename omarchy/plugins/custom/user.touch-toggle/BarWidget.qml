import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.touch-toggle"

  property bool touchscreenOn: true
  property bool touchpadOn: true
  property bool kbdBacklightOn: false

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function runCmd(cmd) {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(cmd)
    } else {
      actionProc.command = ["bash", "-c", cmd]
      actionProc.running = true
    }
  }

  function openMenu() {
    root.runCmd("omarchy-touch-menu")
  }

  function toggleTouchscreen() {
    root.runCmd("omarchy-toggle-touchscreen")
    root.touchscreenOn = !root.touchscreenOn
    refreshTimer.restart()
  }

  function toggleKbdBacklight() {
    root.runCmd("asus-kbd-sync toggle")
    root.kbdBacklightOn = !root.kbdBacklightOn
    refreshTimer.restart()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: actionProc
    command: ["true"]
  }

  Process {
    id: checkProc
    command: ["bash", "-c", "[ -f \"$HOME/.local/state/omarchy/toggles/hypr/touchscreen-disabled-name\" ] && echo 'ts:0' || echo 'ts:1'; [ -f \"$HOME/.local/state/omarchy/toggles/hypr/touchpad-disabled-name\" ] && echo 'tp:0' || echo 'tp:1'; kb=$(brightnessctl --device='asus::kbd_backlight' get 2>/dev/null || echo 0); [ \"$kb\" -gt 0 ] && echo 'kb:1' || echo 'kb:0'"]
    stdout: SplitParser {
      onRead: function(line) {
        var str = String(line).trim()
        var parts = str.split(":")
        if (parts.length >= 2) {
          if (parts[0] === "ts") root.touchscreenOn = (parts[1] === "1")
          if (parts[0] === "tp") root.touchpadOn = (parts[1] === "1")
          if (parts[0] === "kb") root.kbdBacklightOn = (parts[1] === "1")
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.touchscreenOn ? "󰝁" : "󰝂"
    active: root.touchscreenOn
    tooltipText: "Touch & Input Controls" +
                 "\nTouchscreen: " + (root.touchscreenOn ? "ON" : "DISABLED") +
                 "\nTouchpad: " + (root.touchpadOn ? "ON" : "DISABLED") +
                 "\nKeyboard Backlight: " + (root.kbdBacklightOn ? "ON" : "OFF") +
                 "\n\n• Left-Click: Open Menu" +
                 "\n• Right-Click: Quick Toggle Touchscreen" +
                 "\n• Middle-Click: Quick Toggle Keyboard Backlight"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.toggleTouchscreen()
      } else if (b === Qt.MiddleButton) {
        root.toggleKbdBacklight()
      } else {
        root.openMenu()
      }
    }
  }
}
