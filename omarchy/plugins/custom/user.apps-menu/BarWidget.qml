import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "user.apps-menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleApps() {
    if (root.bar) {
      root.bar.run("omarchy-menu toggle apps")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰀻"
    active: true
    tooltipText: "Applications\nClick to open installed apps menu\nRight-click for system menu"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        if (root.bar) root.bar.run("omarchy-menu toggle root")
      } else {
        root.toggleApps()
      }
    }
  }
}
