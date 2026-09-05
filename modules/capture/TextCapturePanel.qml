import QtQuick
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var captureState
    required property var coordinator
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "Text capture"
        contentWidth: 440
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            Text {
                width: parent.width
                text: root.captureState.status
                color: root.captureState.recording ? Theme.danger : Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: "Area OCR"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.captureState.ocrReason
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            ActionButton {
                width: parent.width
                text: "Select area and copy text"
                enabled: root.captureState.ocrAvailable && !root.captureState.busy
                onClicked: {
                    const capture = root.captureState
                    root.coordinator.close("select-text-area")
                    capture.startOcr()
                }
            }

            Text {
                width: parent.width
                text: "Local dictation"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.captureState.dictationReason
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: root.captureState.stopping ? "Stopping…" : root.captureState.recording ? "Stop and transcribe" : "Start microphone"
                    enabled: (root.captureState.recording && !root.captureState.stopping) || (root.captureState.dictationAvailable && !root.captureState.busy)
                    selected: root.captureState.recording
                    onClicked: {
                        if (root.captureState.recording) root.captureState.stopDictation()
                        else root.captureState.startDictation()
                    }
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Cancel"
                    enabled: root.captureState.canCancel
                    onClicked: root.captureState.cancel()
                }
            }

            Text {
                width: parent.width
                text: "Uses the default microphone and an existing local model. Stop transcribes and copies text. Cancel discards the capture."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                visible: root.captureState.error !== ""
                text: root.captureState.error
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            ActionButton {
                width: parent.width
                text: "Recheck local tools"
                enabled: !root.captureState.busy
                onClicked: root.captureState.refreshAvailability()
            }
        }
    }
}
