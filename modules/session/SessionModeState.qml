import QtQuick

QtObject {
    id: root

    required property var notificationState

    readonly property string mode: currentMode
    readonly property string title: mode === "work" ? "Work" : mode === "presentation" ? "Presentation" : "Normal"
    readonly property bool active: mode !== "normal"
    readonly property bool inhibitIdle: mode === "presentation"
    readonly property int remainingSeconds: mode === "work" ? Math.max(0, Math.ceil((deadline - now) / 1000)) : 0

    property string currentMode: "normal"
    property bool originalDnd: false
    property bool ownsDnd: false
    property bool changingDnd: false
    property double deadline: 0
    property double now: Date.now()

    function setMode(modeName: string): bool {
        if (["normal", "work", "presentation"].indexOf(modeName) === -1) return false
        if (modeName === mode) return true
        if (modeName === "normal") {
            endMode()
            return true
        }
        if (!notificationState) return false
        if (!active) {
            originalDnd = notificationState.doNotDisturb
            changingDnd = true
            notificationState.doNotDisturb = true
            changingDnd = false
            ownsDnd = true
        }
        now = Date.now()
        deadline = modeName === "work" ? now + 25 * 60 * 1000 : 0
        currentMode = modeName
        return true
    }

    function endMode(): void {
        if (!active) return
        if (ownsDnd && notificationState && notificationState.doNotDisturb) {
            changingDnd = true
            notificationState.doNotDisturb = originalDnd
            changingDnd = false
        }
        ownsDnd = false
        currentMode = "normal"
        deadline = 0
    }

    property Connections dndChanges: Connections {
        target: root.notificationState
        function onDoNotDisturbChanged() {
            if (root.active && !root.changingDnd) root.ownsDnd = false
        }
    }

    property Timer countdown: Timer {
        interval: 1000
        repeat: true
        running: root.mode === "work"
        onTriggered: {
            root.now = Date.now()
            if (root.remainingSeconds === 0) root.endMode()
        }
    }

    Component.onDestruction: root.endMode()
}
