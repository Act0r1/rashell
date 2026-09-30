import QtQuick
import qs.core
import qs.ui

Column {
    id: root
    required property var notificationState
    spacing: Theme.spaceLg

    Row {
        width: parent.width
        spacing: Theme.spaceLg

        Rectangle {
            width: 40
            height: 40
            radius: Theme.radius
            color: Theme.selectedSurface
            ShellIcon {
                anchors.centerIn: parent
                name: root.notificationState.doNotDisturb ? "bell-off" : "bell"
                tint: Theme.accent
            }
        }

        Column {
            width: parent.width - 40 - parent.spacing
            spacing: Theme.spaceSm
            Text {
                width: parent.width
                text: root.notificationState.timedDoNotDisturb
                    ? "Paused for " + Math.ceil(root.notificationState.remainingSeconds / 60) + " more min"
                    : root.notificationState.doNotDisturb ? "Paused until turned off" : "Notifications are on"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: "Paused popups still appear in notification history."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spaceMd
        ActionButton {
            width: (parent.width - parent.spacing) / 2
            text: "Pause 25 min"
            accessibleName: "Pause notification popups for 25 minutes"
            onClicked: root.notificationState.pauseFor(25)
        }
        ActionButton {
            width: (parent.width - parent.spacing) / 2
            text: "Pause 1 hour"
            accessibleName: "Pause notification popups for one hour"
            onClicked: root.notificationState.pauseFor(60)
        }
    }

    ActionButton {
        width: parent.width
        text: root.notificationState.doNotDisturb ? "Resume notifications" : "Pause until I turn it off"
        selected: root.notificationState.doNotDisturb
        onClicked: root.notificationState.setDoNotDisturb(!root.notificationState.doNotDisturb)
    }
}
