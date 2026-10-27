import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root

    required property var state
    required property var textCaptureState
    required property var coordinator
    required property var configStore
    required property string outputName

    readonly property string elapsedText: {
        const seconds = root.state.elapsedSeconds
        const minutes = Math.floor(seconds / 60)
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }

    implicitWidth: root.state.recording ? recordingContent.implicitWidth + Theme.spaceLg * 2 : Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    function togglePanel() {
        root.coordinator.toggle(
            "screenshot",
            root,
            "center",
            Quickshell.shellDir + "/modules/system/ScreenshotPanel.qml",
            {
                coordinator: root.coordinator,
                captureState: root.state,
                textCaptureState: root.textCaptureState,
                configStore: root.configStore,
                outputName: root.outputName
            }
        )
    }

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.recording ? "Stop screen recording" : "Open screen capture"
        Accessible.role: Accessible.Button

        contentItem: Item {
            Row {
                id: recordingContent
                anchors.centerIn: parent
                spacing: Theme.spaceSm

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.state.recording && root.state.paused ? "play" : root.state.recording ? "circle-dot" : "camera"
                    tint: root.state.recording ? Theme.danger : Theme.text
                    implicitWidth: Theme.fontTitle
                    implicitHeight: Theme.fontTitle
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.state.recording
                    text: root.elapsedText
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.features: { "tnum": 1 }
                }
            }
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
            if (root.state.recording) root.state.stop()
            else root.togglePanel()
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.togglePanel()
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
