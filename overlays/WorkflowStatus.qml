import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root

    required property var coordinator
    required property var modeState
    required property var captureState
    property bool locked: false

    readonly property var targetScreen: {
        const name = coordinator.preferredOutputName()
        const screens = Quickshell.screens
        for (let index = 0; index < screens.length; index++) {
            if (screens[index].name === name) return screens[index]
        }
        return screens.length > 0 ? screens[0] : null
    }

    PanelWindow {
        screen: root.targetScreen
        visible: screen !== null && !root.locked && (root.modeState.active || root.captureState.busy)
            && !(root.captureState.busy && root.captureState.pendingAction === "ocr")
        implicitWidth: Math.min(480, screen ? screen.width - 24 : 480)
        implicitHeight: content.implicitHeight + Theme.spaceLg * 2
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; right: true }
        margins { bottom: 12; right: 12 }
        WlrLayershell.namespace: "rashell-workflow-status"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: Theme.radius
            border.color: root.captureState.recording ? Theme.danger : Theme.borderInteractive
            border.width: Theme.borderWidth

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceMd

                Row {
                    width: parent.width
                    visible: root.modeState.active
                    spacing: Theme.spaceMd

                    Text {
                        width: parent.width - endModeButton.width - parent.spacing
                        height: Theme.controlHeight
                        text: root.modeState.title + (root.modeState.mode === "work"
                            ? " · " + Math.floor(root.modeState.remainingSeconds / 60) + ":"
                                + String(root.modeState.remainingSeconds % 60).padStart(2, "0") : " · screen awake")
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        id: endModeButton
                        text: "End mode"
                        accessibleName: "End " + root.modeState.title.toLowerCase() + " mode"
                        onClicked: root.modeState.endMode()
                    }
                }

                Row {
                    width: parent.width
                    visible: root.captureState.busy
                    spacing: Theme.spaceMd

                    Text {
                        width: parent.width - cancelCaptureButton.width
                            - (stopCaptureButton.visible ? stopCaptureButton.width + parent.spacing : 0) - parent.spacing
                        height: Theme.controlHeight
                        text: root.captureState.recording ? "● Recording microphone" : root.captureState.status
                        color: root.captureState.recording ? Theme.danger : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        id: stopCaptureButton
                        visible: root.captureState.recording
                        enabled: !root.captureState.stopping
                        text: "Finish"
                        accessibleName: "Stop recording and transcribe"
                        onClicked: root.captureState.stopDictation()
                    }

                    ActionButton {
                        id: cancelCaptureButton
                        text: "Cancel"
                        enabled: root.captureState.canCancel
                        accessibleName: "Cancel text capture and discard recording"
                        onClicked: root.captureState.cancel()
                    }
                }
            }
        }
    }
}
