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
    readonly property string outputPath: configHome + "/rashell/telegram.tdesktop-theme"
    property string desiredTheme: ""
    property string attemptedTheme: ""
    property bool exportSucceeded: false

    function queueExport(): void {
        if (!configStore.hasValidFile) return
        if (configStore.theme === desiredTheme && (exportProcess.running || exportSucceeded)) return
        desiredTheme = configStore.theme
        exportTimer.restart()
    }

    function exportTheme(): void {
        if (exportProcess.running || desiredTheme === ""
                || (desiredTheme === attemptedTheme && exportSucceeded)) return
        attemptedTheme = desiredTheme
        exportSucceeded = false
        exportProcess.command = [
            "python3", Quickshell.shellDir + "/scripts/telegram-theme.py",
            "--theme", attemptedTheme, "--output", outputPath
        ]
        exportProcess.running = true
    }

    Connections {
        target: root.configStore
        function onConfigLoaded() { root.queueExport() }
        function onThemeChanged() { root.queueExport() }
    }

    Timer {
        id: exportTimer
        interval: 100
        onTriggered: root.exportTheme()
    }

    Process {
        id: exportProcess
        stderr: StdioCollector {
            id: errorOutput
        }
        onExited: function(exitCode, exitStatus) {
            root.exportSucceeded = exitCode === 0 && exitStatus === 0
            const detail = errorOutput.text.trim()
            if (!root.exportSucceeded) {
                console.warn("Telegram theme export (" + root.attemptedTheme + ") failed: exit "
                    + exitCode + ", status " + exitStatus + (detail !== "" ? ": " + detail : ""))
            } else if (detail !== "") {
                console.warn("Telegram theme export: " + detail)
            }
        }
        onRunningChanged: {
            if (!running && root.desiredTheme !== root.attemptedTheme) exportTimer.restart()
        }
    }

    Component.onCompleted: queueExport()
}
