import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.dev-workflows"

  property string activeIcon: "󰑮"
  property string activeName: "AI-Assisted Prototyping"
  property string activeId: "ai-assisted"
  property string runningAgents: "idle"
  property int runningCount: 0

  function runCmd(cmd) {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(cmd)
    } else {
      actionProc.command = ["bash", "-c", cmd]
      actionProc.running = true
    }
  }

  function openMenu() {
    root.runCmd("omarchy-workflow-menu")
  }

  function cycleWorkflow() {
    root.runCmd("omarchy-workflow next")
  }

  function toggleAgentsDashboard() {
    root.runCmd("omarchy-shell shell toggle omarchy.agents")
  }

  Process {
    id: actionProc
    command: ["true"]
  }

  // Reactive JSON state watching: instant updates, 0 CPU polling
  FileView {
    id: configFile
    path: Quickshell.env("XDG_STATE_HOME") ? (Quickshell.env("XDG_STATE_HOME") + "/omarchy/settings/dev-workflows.json") : (Quickshell.env("HOME") + "/.local/state/omarchy/settings/dev-workflows.json")
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseConfig(text())
  }

  function parseConfig(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      var aid = data.active_workflow || "ai-assisted"
      root.activeId = aid
      if (Array.isArray(data.workflows)) {
        for (var i = 0; i < data.workflows.length; i++) {
          if (data.workflows[i].id === aid) {
            root.activeIcon = data.workflows[i].icon || "󰑮"
            root.activeName = data.workflows[i].name || aid
            return
          }
        }
      }
    } catch (e) {}
  }

  // Agent activity detection
  Process {
    id: agentProc
    command: ["bash", "-c", "active=(); pgrep -f 'agy' >/dev/null 2>&1 && active+=(agy); pgrep -f 'hermes' >/dev/null 2>&1 && active+=(hermes); pgrep -f 'claude' >/dev/null 2>&1 && active+=(claude); pgrep -f 'codex' >/dev/null 2>&1 && active+=(codex); pgrep -f 'opencode' >/dev/null 2>&1 && active+=(opencode); pgrep -f 'aider' >/dev/null 2>&1 && active+=(aider); (IFS=,; echo \"${active[*]:-idle}\")"]
    stdout: SplitParser {
      onRead: function(line) {
        var str = String(line).trim()
        root.runningAgents = str
        if (str !== "idle" && str !== "") {
          root.runningCount = str.split(",").length
        } else {
          root.runningCount = 0
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
    onTriggered: {
      if (!agentProc.running) agentProc.running = true
    }
  }

  Component.onCompleted: {
    configFile.reload()
    if (!agentProc.running) agentProc.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.activeIcon
    active: root.runningCount > 0
    tooltipText: "Dev Workflow: " + root.activeName +
                 "\nActive Agents: " + (root.runningCount > 0 ? root.runningAgents.toUpperCase() + " (Running)" : "Idle") +
                 "\n\n• Left-Click: Open Dev & AI Hub Menu" +
                 "\n• Right-Click: Quick Cycle Workflow" +
                 "\n• Middle-Click: Toggle Native Agents Token Panel"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.cycleWorkflow()
      } else if (b === Qt.MiddleButton) {
        root.toggleAgentsDashboard()
      } else {
        root.openMenu()
      }
    }
  }
}
