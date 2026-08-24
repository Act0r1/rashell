import QtQuick
import Quickshell

Scope {
    id: state

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: state.now = new Date()
    }
}
