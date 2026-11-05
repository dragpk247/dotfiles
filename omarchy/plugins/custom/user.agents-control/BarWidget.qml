import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.agents-control"

  property string runningAgent: "idle"
  property var activeList: []

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
    root.runCmd("asus-agent-menu")
  }

  function toggleDashboard() {
    root.runCmd("omarchy-shell shell toggle omarchy.agents")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: actionProc
    command: ["true"]
  }

  Process {
    id: checkProc
    command: ["bash", "-c", "active=(); pgrep -f 'agy' >/dev/null 2>&1 && active+=(agy); pgrep -f 'hermes' >/dev/null 2>&1 && active+=(hermes); pgrep -f 'claude' >/dev/null 2>&1 && active+=(claude); pgrep -f 'codex' >/dev/null 2>&1 && active+=(codex); pgrep -f 'opencode' >/dev/null 2>&1 && active+=(opencode); pgrep -f 'aider' >/dev/null 2>&1 && active+=(aider); (IFS=,; echo \"${active[*]:-idle}\")"]
    stdout: SplitParser {
      onRead: function(line) {
        var str = String(line).trim()
        root.runningAgent = str
        if (str !== "idle" && str !== "") {
          root.activeList = str.split(",")
        } else {
          root.activeList = []
        }
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
    tooltipText: "AI Agents: " + (root.runningAgent !== "idle" ? root.runningAgent.toUpperCase() : "Idle") +
                 "\n\n• Left-Click: Open Agent Manager & Launchers" +
                 "\n• Right-Click: Toggle Native Omarchy 4.5.0 Token Dashboard"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.toggleDashboard()
      } else {
        root.openMenu()
      }
    }
  }
}
