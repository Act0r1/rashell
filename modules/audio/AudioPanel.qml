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

    component SectionLabel: Row {
        id: sectionLabel

        required property string text
        required property string glyph

        spacing: Theme.spaceMd

        Rectangle {
            width: 24
            height: 24
            radius: Theme.radius
            color: Theme.selectedSurface

            Text {
                anchors.centerIn: parent
                text: sectionLabel.glyph
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }
        }

        Text {
            height: 24
            text: sectionLabel.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
        }
    }

    component DeviceButton: ActionButton {
        id: deviceButton

        width: parent.width
        height: Theme.rowHeight
        subtleSelected: true
        flat: true
        alignment: Text.AlignLeft
        leftPadding: Theme.spaceLg + Theme.spaceXl + Theme.spaceMd
        rightPadding: Theme.spaceLg

        contentItem: Text {
            text: deviceButton.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: deviceButton.selected ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            x: Theme.spaceLg
            width: Theme.spaceXl
            height: parent.height
            text: "✓"
            visible: deviceButton.selected
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
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
            text: volumeRow.inputMode ? "Input volume" : "Output volume"
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
            text: volumeRow.muted ? "Unmute" : "Mute"
            flat: true
            danger: volumeRow.muted
            selected: volumeRow.muted
            subtleSelected: true
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
            visible: root.audioState && root.audioState.availability === "loading"
            text: "Connecting to PipeWire..."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            visible: root.audioState && root.audioState.availability === "disconnected"
            text: "PipeWire disconnected. Waiting to reconnect."
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            spacing: Theme.spaceLg
            visible: root.audioState && root.audioState.availability === "no-output"

            SectionLabel { text: "Output"; glyph: "󰕾" }

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
            visible: root.audioState && root.audioState.availability === "ready"

            Item {
                width: parent.width
                height: animationButton.implicitHeight

                SectionLabel {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Output"
                    glyph: "󰕾"
                }

                ActionButton {
                    id: animationButton
                    anchors.right: parent.right
                    text: "Animation"
                    flat: true
                    accessibleName: "Open animated output picker"
                    toolTipText: accessibleName + " · Meta+Shift+H"
                    onClicked: if (root.coordinator) root.coordinator.audioOutputPickerRequested()
                }
            }

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

                    DeviceButton {
                        required property var modelData
                        selected: root.audioState.output !== null && modelData.id === root.audioState.output.id
                        text: root.audioState.nodeLabel(modelData)
                        accessibleName: root.audioState.nodeLabel(modelData) + (selected ? ", in use" : "")
                        onClicked: root.audioState.selectOutput(modelData)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spaceLg
                visible: root.audioState && root.audioState.inputs.length > 0

                SectionLabel { text: "Input"; glyph: "󰍬" }

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

                        DeviceButton {
                            required property var modelData
                            selected: root.audioState.input !== null && modelData.id === root.audioState.input.id
                            text: root.audioState.nodeLabel(modelData)
                            accessibleName: root.audioState.nodeLabel(modelData) + (selected ? ", in use" : "")
                            onClicked: root.audioState.selectInput(modelData)
                        }
                    }
                }
            }
        }
    }
}
