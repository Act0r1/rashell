import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root
    required property var state
    required property var coordinator
    required property string outputName
    implicitWidth: tokenContent.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: "Token usage " + root.state.compact(root.state.totalTokens)

        contentItem: Item {
            Row {
                id: tokenContent
                anchors.centerIn: parent
                spacing: Theme.spaceSm

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "brain-circuit"
                    tint: Theme.textMuted
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.state.compact(root.state.totalTokens)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "tokens"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }
        onClicked: root.coordinator.toggle(
            "tokens", root, "right",
            Quickshell.shellDir + "/modules/system/TokenPanel.qml",
            { coordinator: root.coordinator, tokenState: root.state }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("tokens", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("tokens", outputName, root)
}
