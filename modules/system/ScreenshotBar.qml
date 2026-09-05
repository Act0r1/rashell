import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property var configStore
    required property string outputName

    implicitWidth: Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.recording ? "Open screen recording controls" : "Open screen capture"
        Accessible.role: Accessible.Button

        contentItem: Text {
            text: root.state.recording && root.state.paused ? "󰐊" : root.state.recording ? "󰑋" : "󰄀"
            color: root.state.recording ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "screenshot"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: root.state.recording ? Theme.danger : active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: {
            root.coordinator.toggle(
                "screenshot",
                root,
                "center",
                Quickshell.shellDir + "/modules/system/ScreenshotPanel.qml",
                {
                    coordinator: root.coordinator,
                    captureState: root.state,
                    configStore: root.configStore,
                    outputName: root.outputName
                }
            )
        }
    }

    Rectangle {
        visible: root.state.recording
        anchors {
            top: parent.top
            right: parent.right
            margins: 3
        }
        width: 6
        height: 6
        radius: 3
        color: Theme.danger

        SequentialAnimation on opacity {
            running: root.state.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 600 }
            NumberAnimation { to: 1; duration: 600 }
        }
    }

    Component.onCompleted: coordinator.registerAnchor("screenshot", outputName, root, "center")
    Component.onDestruction: coordinator.unregisterAnchor("screenshot", outputName, root)
}
