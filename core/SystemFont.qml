import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property ConfigStore configStore
    readonly property string configHome: {
        const configured = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        return configured.charAt(0) === "/" ? configured : Quickshell.env("HOME") + "/.config"
    }
    readonly property string currentFont: configStore.effective.fontFamily === undefined
        ? "" : configStore.fontFamily + "\n" + configStore.fontFallbackFamily
    property string desiredFont: ""
    property string attemptedFont: ""
    property bool syncSucceeded: false

    function queueSync(): void {
        if (!configStore.hasValidFile || currentFont === "") return
        if (currentFont === desiredFont && (syncProcess.running || syncSucceeded)) return
        desiredFont = currentFont
        syncTimer.restart()
    }

    function syncFont(): void {
        if (syncProcess.running || desiredFont === ""
                || (desiredFont === attemptedFont && syncSucceeded)) return
        attemptedFont = desiredFont
        syncSucceeded = false
        const parts = attemptedFont.split("\n")
        syncProcess.command = [
            "python3", Quickshell.shellDir + "/scripts/system-font.py",
            "--family", parts[0], "--fallback", parts[1], "--config-home", configHome
        ]
        syncProcess.running = true
    }

    Connections {
        target: root.configStore
        function onConfigLoaded() { root.queueSync() }
    }

    Timer {
        id: syncTimer
        interval: 100
        onTriggered: root.syncFont()
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
                console.warn("System font sync (" + root.attemptedFont.replace("\n", " + ") + ") failed: exit "
                    + exitCode + ", status " + exitStatus + (detail !== "" ? ": " + detail : ""))
            }
        }
        onRunningChanged: {
            if (!running && root.desiredFont !== root.attemptedFont) syncTimer.restart()
        }
    }

    Component.onCompleted: queueSync()
}
