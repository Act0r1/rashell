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
    readonly property string outputPath: configHome + "/rashell/telegram.tdesktop-palette"
    property string desiredTheme: ""
    property string attemptedTheme: ""

    function queueExport(): void {
        if (!configStore.hasValidFile || configStore.theme === desiredTheme) return
        desiredTheme = configStore.theme
        exportTimer.restart()
    }

    function exportTheme(): void {
        if (exportProcess.running || desiredTheme === "" || desiredTheme === attemptedTheme) return
        attemptedTheme = desiredTheme
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
            const detail = errorOutput.text.trim()
            if (exitCode !== 0 || exitStatus !== 0) {
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
