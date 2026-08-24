import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property var osd
    required property var feedback
    required property string outputName

    implicitWidth: 96
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.status === "ready"
            ? (root.state.outputMuted ? "Audio muted" : "Audio volume " + Math.round(root.state.outputVolume * 100) + " percent")
            : "Audio " + root.state.status
        Accessible.role: Accessible.Button

        contentItem: Row {
            spacing: Theme.spaceMd

            Text {
                text: root.state.status === "loading" ? "AUDIO ..."
                    : root.state.status !== "ready" ? "AUDIO !"
                    : root.state.outputMuted ? "MUTE" : "VOL"
                color: root.state.outputMuted ? Theme.danger
                    : root.state.status === "ready" ? Theme.accentMuted : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Text {
                visible: root.state.status === "ready"
                text: Math.round(root.state.outputVolume * 100) + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "audio"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "audio",
            root,
            "right",
            Quickshell.shellDir + "/modules/audio/AudioPanel.qml",
            { coordinator: root.coordinator, audioState: root.state }
        )

        WheelHandler {
            onWheel: function(event) {
                if (event.angleDelta.y === 0) return
                if (!root.state.adjustOutputDirect(event.angleDelta.y > 0 ? 0.05 : -0.05, root.outputName)) {
                    root.feedback.show(root.outputName, "AUDIO UNAVAILABLE")
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                if (!root.state.toggleOutputMuteDirect(root.outputName)) {
                    root.feedback.show(root.outputName, "AUDIO UNAVAILABLE")
                }
            }
        }
    }

    Component.onCompleted: coordinator.registerAnchor("audio", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("audio", outputName, root)
}
