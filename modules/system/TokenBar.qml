import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

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
        Accessible.name: "Token usage " + root.state.compact(root.state.totalTokens)

        contentItem: Row {
            id: tokenContent
            spacing: Theme.spaceSm

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰧑"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.compact(root.state.totalTokens)
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }
        }
        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "tokens"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
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
