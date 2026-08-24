pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    property var coordinator: null
    property var audioState: null

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    component SectionLabel: Text {
        color: Theme.accentMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
        font.letterSpacing: 2
    }

    component VolumeRow: Item {
        id: volumeRow

        required property var state
        required property bool inputMode

        readonly property var node: inputMode ? state.input : state.output
        readonly property real currentVolume: inputMode ? state.inputVolume : state.outputVolume
        readonly property bool muted: inputMode ? state.inputMuted : state.outputMuted

        implicitHeight: 58

        Text {
            anchors {
                left: parent.left
                top: parent.top
            }
            text: volumeRow.inputMode ? "INPUT VOLUME" : "OUTPUT VOLUME"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        LevelSlider {
            id: slider
            anchors {
                left: parent.left
                right: percentage.left
                bottom: parent.bottom
                rightMargin: Theme.spaceLg
            }
            value: volumeRow.currentVolume
            accessibleName: volumeRow.inputMode ? "Input volume" : "Output volume"
            onMoved: {
                if (volumeRow.inputMode) volumeRow.state.setInputVolume(value)
                else volumeRow.state.setOutputVolume(value)
            }
        }

        Text {
            id: percentage
            anchors {
                right: muteButton.left
                rightMargin: Theme.spaceLg
                verticalCenter: slider.verticalCenter
            }
            text: Math.round(volumeRow.currentVolume * 100) + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        ActionButton {
            id: muteButton
            anchors {
                right: parent.right
                verticalCenter: slider.verticalCenter
            }
            width: 82
            text: volumeRow.muted ? "UNMUTE" : "MUTE"
            danger: volumeRow.muted
            selected: volumeRow.muted
            accessibleName: (volumeRow.inputMode ? "Input" : "Output") + (volumeRow.muted ? " muted" : " unmuted")
            onClicked: {
                if (volumeRow.inputMode) volumeRow.state.toggleInputMute()
                else volumeRow.state.toggleOutputMute()
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        onActivated: if (root.coordinator) root.coordinator.close("escape")
    }

    PanelFrame {
        id: frame
        anchors.fill: parent
        title: "Audio"
        contentWidth: 460
        onCloseRequested: if (root.coordinator) root.coordinator.close("close-control")

        Text {
            visible: root.audioState && root.audioState.status === "loading"
            text: "Connecting to PipeWire..."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            visible: root.audioState && root.audioState.status === "disconnected"
            text: "PipeWire disconnected. Waiting to reconnect."
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            spacing: Theme.spaceLg
            visible: root.audioState && root.audioState.status === "no-output"

            SectionLabel { text: "OUTPUT" }

            Text {
                text: "No output devices"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }
        }

        Column {
            id: controls
            width: parent.width
            spacing: Theme.spaceLg
            visible: root.audioState && root.audioState.status === "ready"

            SectionLabel { text: "OUTPUT" }

            VolumeRow {
                width: parent.width
                state: root.audioState
                inputMode: false
            }

            Column {
                width: parent.width
                spacing: Theme.spaceXs

                Repeater {
                    model: root.audioState ? root.audioState.outputs : []

                    ActionButton {
                        required property var modelData
                        width: parent.width
                        height: Theme.rowHeight
                        selected: root.audioState.output !== null && modelData.id === root.audioState.output.id
                        subtleSelected: true
                        text: (selected ? "✓ " : "  ") + root.audioState.nodeLabel(modelData)
                            + (selected ? "    IN USE" : "")
                        accessibleName: root.audioState.nodeLabel(modelData) + (selected ? ", in use" : "")
                        onClicked: root.audioState.selectOutput(modelData)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spaceLg
                visible: root.audioState && root.audioState.inputs.length > 0

                SectionLabel { text: "INPUT" }

                VolumeRow {
                    width: parent.width
                    state: root.audioState
                    inputMode: true
                    visible: root.audioState.inputUsable
                }

                Text {
                    visible: !root.audioState.inputUsable
                    text: "Select an input device"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }

                Column {
                    width: parent.width
                    spacing: Theme.spaceXs

                    Repeater {
                        model: root.audioState ? root.audioState.inputs : []

                        ActionButton {
                            required property var modelData
                            width: parent.width
                            height: Theme.rowHeight
                            selected: root.audioState.input !== null && modelData.id === root.audioState.input.id
                            subtleSelected: true
                            text: (selected ? "✓ " : "  ") + root.audioState.nodeLabel(modelData)
                                + (selected ? "    IN USE" : "")
                            accessibleName: root.audioState.nodeLabel(modelData) + (selected ? ", in use" : "")
                            onClicked: root.audioState.selectInput(modelData)
                        }
                    }
                }
            }
        }
    }
}
