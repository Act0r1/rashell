import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state
    property string layoutName: "Unknown"
    readonly property string shortName: {
        const value = layoutName.toLowerCase()
        if (value.indexOf("russian") !== -1) return "RU"
        if (value.indexOf("english") !== -1) return "US"
        return layoutName.slice(0, 3).toUpperCase()
    }

    function refresh() {
        if (!query.running) query.running = true
    }

    function cycle() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        delayedRefresh.restart()
    }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value !== "") state.layoutName = value
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refresh()
    }

    Timer {
        id: delayedRefresh
        interval: 150
        onTriggered: state.refresh()
    }
}
