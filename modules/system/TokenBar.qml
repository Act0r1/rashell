import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    required property var state
    required property var coordinator
    required property string outputName
    implicitWidth: label.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Token usage " + root.state.compact(root.state.totalTokens)

        contentItem: Text {
            id: label
            text: "󰧑 " + root.state.compact(root.state.totalTokens)
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
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
