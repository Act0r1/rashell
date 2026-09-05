import QtQuick
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var modeState
    implicitWidth: 400
    implicitHeight: frame.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: frame
        width: parent.width
        title: "Session mode"
        onCloseRequested: root.coordinator.close("close-mode")

        ModeControls {
            width: parent.width
            state: root.modeState
        }
    }
}
