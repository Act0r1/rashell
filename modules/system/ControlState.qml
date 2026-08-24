import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state

    property bool networkEnabled: true
    property string networkName: "Not connected"
    property bool bluetoothEnabled: false
    property string bluetoothDevice: "No connected device"
    property real brightness: -1

    function refresh() {
        if (!status.running) status.running = true
    }

    function toggleNetwork() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", networkEnabled ? "off" : "on"])
        delayedRefresh.restart()
    }

    function openNetworkSettings() {
        Quickshell.execDetached(["nm-connection-editor"])
    }

    function toggleBluetooth() {
        Quickshell.execDetached(["bluetoothctl", "power", bluetoothEnabled ? "off" : "on"])
        delayedRefresh.restart()
    }

    function setBrightness(value) {
        if (brightness < 0) return
        const percent = Math.max(1, Math.min(100, Math.round(Number(value) * 100)))
        brightness = percent / 100
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", percent + "%"])
        delayedRefresh.restart()
    }

    Process {
        id: status
        command: [
            "sh", "-c",
            "wifi=$(nmcli radio wifi 2>/dev/null); "
                + "ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -n1); "
                + "bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}'); "
                + "btdev=$(bluetoothctl devices Connected 2>/dev/null | sed -n '1s/^Device [^ ]* //p'); "
                + "backlight=$(find /sys/class/backlight -mindepth 1 -maxdepth 1 -type l 2>/dev/null | head -n1); "
                + "if [ -n \"$backlight\" ]; then current=$(cat \"$backlight/brightness\"); max=$(cat \"$backlight/max_brightness\"); b=$(awk -v c=\"$current\" -v m=\"$max\" 'BEGIN {printf \"%.0f\", 100*c/m}'); else b=-1; fi; "
                + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$wifi\" \"${ssid:-Not connected}\" \"$bt\" \"${btdev:-No connected device}\" \"$b\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split("\n")
                state.networkEnabled = values.length > 0 && values[0] === "enabled"
                state.networkName = values.length > 1 ? values[1] : "Not connected"
                state.bluetoothEnabled = values.length > 2 && values[2] === "yes"
                state.bluetoothDevice = values.length > 3 ? values[3] : "No connected device"
                const brightnessPercent = values.length > 4 ? Number(values[4]) : -1
                state.brightness = brightnessPercent >= 0 ? brightnessPercent / 100 : -1
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
