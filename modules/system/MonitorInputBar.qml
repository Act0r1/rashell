import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root
    required property var coordinator
    required property string outputName
    implicitWidth: Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    function togglePanel() {
        coordinator.toggle("monitor-input", root, "right",
            Quickshell.shellDir + "/modules/system/MonitorInputPanel.qml",
            { coordinator: coordinator, inputState: inputState })
    }

    MonitorInputState { id: inputState; outputName: root.outputName }

    Button {
        id: button
        anchors.fill: parent
        padding: 0
        hoverEnabled: true
        Accessible.name: "Monitor input"
        contentItem: Item {
            ShellIcon { anchors.centerIn: parent; name: "monitor"; tint: Theme.textMuted }
        }
        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "monitor-input"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }
        BarToolTip { visible: button.hovered; text: "Monitor input" }
        onClicked: root.togglePanel()
    }
    Component.onCompleted: coordinator.registerAnchor("monitor-input", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("monitor-input", outputName, root)
}
