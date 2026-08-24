import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state
    property var snapshot: ({})
    readonly property var today: snapshot.periods && snapshot.periods.today ? snapshot.periods.today : ({})
    readonly property real totalTokens: Number(today.totalTokens || 0)
    readonly property real cost: Number(today.cost || 0)
    readonly property real cacheRate: Number(today.cacheRate || 0)
    readonly property int sessions: Number(today.sessions || 0)

    function refresh() {
        if (!query.running) query.running = true
    }

    function compact(value) {
        if (value >= 1000000000) return (value / 1000000000).toFixed(1) + "B"
        if (value >= 1000000) return (value / 1000000).toFixed(value >= 10000000 ? 0 : 1) + "M"
        if (value >= 1000) return (value / 1000).toFixed(0) + "K"
        return String(Math.round(value))
    }

    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/noctalia/token-meter/token-meter.py", "snapshot"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    state.snapshot = JSON.parse(text)
                } catch (error) {
                    console.warn("Token meter snapshot rejected: " + error)
                }
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refresh()
    }
}
