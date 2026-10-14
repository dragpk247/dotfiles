import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.gpu-switcher"

  property string gpuMode: "Unknown"
  readonly property bool isHybrid: gpuMode.toLowerCase() === "hybrid" || gpuMode.toLowerCase() === "dedicated"

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function toggle() {
    if (!switchProc.running) {
      switchProc.command = ["omarchy-gpu-switch", "toggle"]
      switchProc.running = true
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: checkProc
    command: ["omarchy-gpu-switch", "status"]
    stdout: SplitParser {
      onRead: function(line) {
        var mode = String(line).trim()
        if (mode) {
          root.gpuMode = mode
        }
      }
    }
  }

  Process {
    id: switchProc
    onExited: function(exitCode, exitStatus) {
      refreshTimer.restart()
      root.refresh()
    }
  }

  Timer {
    id: refreshTimer
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.isHybrid ? "󰢮" : "󰢯"
    active: root.isHybrid
    tooltipText: "GPU Mode: " + root.gpuMode + " (Click to toggle Integrated / Hybrid)"
    onPressed: function(b) {
      root.toggle()
    }
  }
}
