pragma ComponentBehavior: Bound

import QtQuick
import qs.core
import qs.ui

Column {
    id: root

    required property var state
    spacing: Theme.spaceMd

    Text {
        width: parent.width
        text: "Session mode"
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.bold: true
    }

    Row {
        width: parent.width
        spacing: Theme.spaceSm

        Repeater {
            model: ["normal", "work", "presentation"]

            ActionButton {
                required property string modelData
                width: (root.width - Theme.spaceSm * 2) / 3
                text: modelData === "work" ? "Work" : modelData === "presentation" ? "Present" : "Normal"
                accessibleName: modelData === "presentation" ? "Presentation mode" : text + " mode"
                selected: root.state.mode === modelData
                onClicked: root.state.setMode(modelData)
            }
        }
    }

    Text {
        width: parent.width
        text: root.state.mode === "work"
            ? "Work · " + Math.floor(root.state.remainingSeconds / 60) + ":"
                + String(root.state.remainingSeconds % 60).padStart(2, "0") + " remaining"
            : root.state.mode === "presentation" ? "Presentation · keeping the screen awake" : "Normal session"
        color: root.state.active ? Theme.accent : Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }

    Text {
        width: parent.width
        visible: root.state.active
        text: root.state.notificationState.doNotDisturb ? "Notifications are silenced." : "Notifications are allowed."
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }
}
