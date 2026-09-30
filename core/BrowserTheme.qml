import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property ConfigStore configStore
    readonly property bool supportedSession: {
        const desktops = (String(Quickshell.env("XDG_CURRENT_DESKTOP") || "") + ":"
            + String(Quickshell.env("XDG_SESSION_DESKTOP") || "")).toLowerCase().split(":")
        return desktops.indexOf("niri") === -1 && !Quickshell.env("NIRI_SOCKET")
            && (desktops.indexOf("hyprland") !== -1 || !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
    }
    property string desiredTheme: ""
    property string attemptedTheme: ""
    property bool syncSucceeded: false

    function queueSync(): void {
        if (!supportedSession || !configStore.hasValidFile) return
        if (configStore.theme === desiredTheme && (syncProcess.running || syncSucceeded)) return
        desiredTheme = configStore.theme
        syncTimer.restart()
    }

    function syncTheme(): void {
        if (syncProcess.running || desiredTheme === ""
                || (desiredTheme === attemptedTheme && syncSucceeded)) return
        attemptedTheme = desiredTheme
        syncSucceeded = false
        syncProcess.command = [
            "python3", Quickshell.shellDir + "/scripts/browser-theme.py",
            "--theme", attemptedTheme, "--sync-brave"
        ]
        syncProcess.running = true
    }

    Connections {
        target: root.configStore
        function onConfigLoaded() { root.queueSync() }
        function onThemeChanged() { root.queueSync() }
    }

    Timer {
        id: syncTimer
        interval: 100
        onTriggered: root.syncTheme()
    }

    Process {
        id: syncProcess
        stderr: StdioCollector {
            id: errorOutput
        }
        onExited: function(exitCode, exitStatus) {
            root.syncSucceeded = exitCode === 0 && exitStatus === 0
            const detail = errorOutput.text.trim()
            if (!root.syncSucceeded) {
                console.warn("Browser theme sync (" + root.attemptedTheme + ") failed: exit "
                    + exitCode + ", status " + exitStatus + (detail !== "" ? ": " + detail : ""))
            }
        }
        onRunningChanged: {
            if (!running && root.desiredTheme !== root.attemptedTheme) syncTimer.restart()
        }
    }

    Component.onCompleted: queueSync()
}
