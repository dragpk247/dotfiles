import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.agents-control"

  property string runningAgent: "idle"

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function openMenu() {
    if (root.bar) {
      root.bar.run("asus-agent-menu")
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: checkProc
    command: ["bash", "-c", "if pgrep -x agy >/dev/null 2>&1; then echo agy; elif pgrep -x claude >/dev/null 2>&1; then echo claude; elif pgrep -x codex >/dev/null 2>&1; then echo codex; else echo idle; fi"]
    stdout: SplitParser {
      onRead: function(line) {
        root.runningAgent = String(line).trim()
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩"
    active: root.runningAgent !== "idle"
    tooltipText: "AI Agents: " + (root.runningAgent !== "idle" ? root.runningAgent.toUpperCase() + " (Running)" : "Idle") + "\nClick to open launcher & status menu"
    onPressed: function(b) {
      root.openMenu()
    }
  }
}
