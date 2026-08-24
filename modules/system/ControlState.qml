import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state
    property bool networkEnabled: true
    property bool bluetoothEnabled: false

    function refresh() {
        if (!status.running) status.running = true
    }

    function toggleNetwork() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", networkEnabled ? "off" : "on"])
        delayedRefresh.restart()
    }

    function toggleBluetooth() {
        Quickshell.execDetached(["bluetoothctl", "power", bluetoothEnabled ? "off" : "on"])
        delayedRefresh.restart()
    }

    Process {
        id: status
        command: ["sh", "-c", "printf '%s ' \"$(nmcli radio wifi 2>/dev/null)\"; bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split(/\s+/)
                state.networkEnabled = values.length > 0 && values[0] === "enabled"
                state.bluetoothEnabled = values.length > 1 && values[1] === "yes"
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: state.refresh()
    }

    Timer {
        id: delayedRefresh
        interval: 700
        onTriggered: state.refresh()
    }
}
