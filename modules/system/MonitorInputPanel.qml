pragma ComponentBehavior: Bound

import QtQuick
import qs.core
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var inputState
    implicitWidth: 340
    implicitHeight: frame.implicitHeight
    Component.onCompleted: inputState.run()
    Keys.onEscapePressed: coordinator.close("escape")

    PanelFrame {
        id: frame
        anchors.fill: parent
        title: "Monitor input"
        contentWidth: root.implicitWidth
        onCloseRequested: root.coordinator.close("close-button")

        Text {
            width: parent.width
            text: root.inputState.model || root.inputState.outputName
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
        }
        Column {
            width: parent.width
            spacing: Theme.spaceSm
            Repeater {
                model: root.inputState.inputs
                ActionButton {
                    required property var modelData
                    width: parent.width
                    text: modelData.label + (selected ? "  ·  Current" : "")
                    alignment: Text.AlignLeft
                    selected: root.inputState.current === modelData.value
                    subtleSelected: true
                    enabled: !root.inputState.busy && root.inputState.error === "" && !selected
                    onClicked: root.inputState.run(modelData.value)
                }
            }
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: root.inputState.busy ? "Reading / switching monitor…"
                : root.inputState.error || root.inputState.message
            color: root.inputState.error ? Theme.danger : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            text: "Choose the input connected to your other device. To return, you may need the monitor's physical buttons."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
        }
        ActionButton {
            width: parent.width
            text: "Refresh"
            enabled: !root.inputState.busy
            onClicked: root.inputState.run()
        }
    }
}
