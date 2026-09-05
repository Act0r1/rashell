import QtQuick
import QtQuick.Dialogs
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var captureState
    required property var configStore
    required property string outputName

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    FolderDialog {
        id: folderDialog
        title: "Choose capture folder"
        currentFolder: encodeURI("file://" + root.configStore.captureDirectoryPath)
        onAccepted: {
            const selected = decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, ""))
            root.configStore.setCaptureDirectory(selected)
        }
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "SCREEN CAPTURE"
        contentWidth: 440
        onCloseRequested: root.coordinator.close("close-capture")

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            Text {
                width: parent.width
                text: root.captureState.recording
                    ? root.captureState.paused ? "Recording paused" : "Recording in progress"
                    : "Screenshots always use a selected region"
                color: root.captureState.recording ? Theme.accent : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }

            ActionButton {
                width: parent.width
                visible: !root.captureState.recording
                text: "󰄀  Screenshot"
                accessibleName: "Take a region screenshot"
                enabled: !root.captureState.busy && !root.captureState.selecting
                onClicked: {
                    root.coordinator.close("start-screenshot")
                    root.captureState.start("screenshot", root.configStore.captureDirectoryPath, root.outputName)
                }
            }

            ActionButton {
                width: parent.width
                visible: !root.captureState.recording
                text: "󰏫  Screenshot + edit"
                accessibleName: "Take and edit a region screenshot"
                enabled: !root.captureState.busy && !root.captureState.selecting
                onClicked: {
                    root.coordinator.close("start-annotation")
                    root.captureState.start("annotate", root.configStore.captureDirectoryPath, root.outputName)
                }
            }

            Text {
                visible: !root.captureState.recording
                text: "VIDEO AREA"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd
                visible: !root.captureState.recording

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Select region"
                    accessibleName: "Record a selected region"
                    selected: root.captureState.captureMode === "region"
                    enabled: !root.captureState.selecting
                    onClicked: root.captureState.selectArea("region", root.outputName)
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Select display"
                    accessibleName: "Record an entire display"
                    selected: root.captureState.captureMode === "output"
                    enabled: !root.captureState.selecting
                    onClicked: root.captureState.selectArea("output", root.outputName)
                }
            }

            Text {
                width: parent.width
                visible: !root.captureState.recording
                text: root.captureState.selecting
                    ? root.captureState.captureMode === "region" ? "Selecting region…" : "Selecting display…"
                    : root.captureState.captureSelection === ""
                        ? root.captureState.captureMode === "region" ? "No region selected" : "No display selected"
                        : root.captureState.captureMode === "region"
                            ? "Selected region: " + root.captureState.captureSelection
                            : "Selected display: " + root.captureState.captureSelection
                color: root.captureState.captureSelection === "" ? Theme.textMuted : Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }

            Text {
                visible: !root.captureState.recording
                text: "VIDEO AUDIO"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd
                visible: !root.captureState.recording

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "None"
                    accessibleName: "Record without audio"
                    selected: root.captureState.audioMode === "none"
                    onClicked: root.captureState.audioMode = "none"
                }

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "System"
                    accessibleName: "Record system audio"
                    selected: root.captureState.audioMode === "system"
                    onClicked: root.captureState.audioMode = "system"
                }

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "Mic"
                    accessibleName: "Record microphone audio"
                    selected: root.captureState.audioMode === "microphone"
                    onClicked: root.captureState.audioMode = "microphone"
                }

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "Both"
                    accessibleName: "Record system and microphone audio"
                    selected: root.captureState.audioMode === "both"
                    onClicked: root.captureState.audioMode = "both"
                }
            }

            ActionButton {
                width: parent.width
                visible: !root.captureState.recording
                text: "󰑋  Start video"
                accessibleName: "Start screen recording"
                enabled: !root.captureState.busy && !root.captureState.selecting
                onClicked: {
                    root.captureState.start(
                        "record",
                        root.configStore.captureDirectoryPath,
                        root.outputName,
                        root.captureState.captureMode,
                        root.captureState.audioMode,
                        root.captureState.captureSelection
                    )
                    root.coordinator.close("start-recording")
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd
                visible: root.captureState.recording

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: root.captureState.paused ? "󰐊  Resume" : "󰏤  Pause"
                    accessibleName: root.captureState.paused ? "Resume screen recording" : "Pause screen recording"
                    selected: root.captureState.paused
                    onClicked: {
                        if (root.captureState.paused) root.captureState.resume()
                        else root.captureState.pause()
                    }
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "󰓛  Stop and save"
                    accessibleName: "Stop and save screen recording"
                    danger: true
                    onClicked: root.captureState.stop()
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.borderWidth
                color: Theme.border
            }

            Text {
                text: "SAVE FOLDER"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                Rectangle {
                    width: parent.width - chooseFolder.width - parent.spacing
                    height: Theme.compactControlSize
                    color: Theme.surfaceRaised
                    border.color: Theme.borderInteractive
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Text {
                        anchors {
                            fill: parent
                            margins: Theme.spaceMd
                        }
                        text: root.configStore.captureDirectoryPath
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideMiddle
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ActionButton {
                    id: chooseFolder
                    text: "Choose…"
                    accessibleName: "Choose capture folder"
                    onClicked: folderDialog.open()
                }
            }
        }
    }
}
