import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state

    property int cpuPercent: 0
    property int memoryPercent: 0
    property int updates: 0

    function refreshStats() {
        if (!statsProcess.running) statsProcess.running = true
    }

    function refreshUpdates() {
        if (!updatesProcess.running) updatesProcess.running = true
    }

    Process {
        id: statsProcess
        command: ["sh", "-c", "LC_ALL=C top -bn1 | awk '/Cpu\\(s\\)/ {cpu=100-$8} /MiB Mem/ {mem=100*$8/$4} END {printf \"%.0f %.0f\\n\", cpu, mem}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split(/\s+/)
                if (values.length >= 2) {
                    state.cpuPercent = Number(values[0]) || 0
                    state.memoryPercent = Number(values[1]) || 0
                }
            }
        }
    }

    Process {
        id: updatesProcess
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: state.updates = Number(text.trim()) || 0
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refreshStats()
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refreshUpdates()
    }
}
