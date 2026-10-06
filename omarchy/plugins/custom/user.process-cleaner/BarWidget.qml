import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.process-cleaner"

  property string memSummary: "Ready"

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  function openMenu() {
    if (root.bar) {
      root.bar.run("omarchy-process-cleaner")
    }
  }

  function quickClean() {
    if (root.bar) {
      root.bar.run("omarchy-process-cleaner --quick")
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: checkProc
    command: ["bash", "-c", "free -h | awk '/^Mem:/ {print $3 \" / \" $2}'"]
    stdout: SplitParser {
      onRead: function(line) {
        root.memSummary = String(line).trim()
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 8000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰃢"
    active: true
    tooltipText: "Process & Memory Cleaner\nRAM: " + root.memSummary + "\nClick to open interactive manager\nRight-click for quick clean"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.quickClean()
      } else {
        root.openMenu()
      }
    }
  }
}
