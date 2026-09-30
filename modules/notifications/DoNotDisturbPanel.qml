import QtQuick
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var notificationState
    implicitWidth: 400
    implicitHeight: panel.implicitHeight

    Shortcut { sequence: "Esc"; onActivated: root.coordinator.close("escape") }

    PanelFrame {
        id: panel
        width: parent.width
        title: "Do not disturb"
        onCloseRequested: root.coordinator.close("close-dnd")
        DoNotDisturbControls {
            width: parent.width
            notificationState: root.notificationState
        }
    }
}
