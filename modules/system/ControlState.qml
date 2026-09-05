import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Scope {
    id: state

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiAvailable: Networking.devices.values.some(device => device.type === DeviceType.Wifi)
    readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled
    readonly property var connectedDevices: Networking.devices.values.filter(device => device.connected)
    readonly property var wifiNetwork: {
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wifi) continue
            for (const network of device.networks.values) {
                if (network.connected) return network
            }
        }
        return null
    }
    readonly property string wifiDetail: !wifiAvailable ? "Unavailable" : wifiBlocked ? "Blocked"
        : !wifiEnabled ? "Off" : wifiNetwork ? wifiNetwork.name : "Not connected"
    readonly property bool networkConnected: connectedDevices.length > 0
    readonly property bool wiredConnected: connectedDevices.some(device => device.type === DeviceType.Wired)
    readonly property string networkLabel: {
        const labels = []
        for (const device of connectedDevices) {
            const label = device.type === DeviceType.Wired ? "Ethernet"
                : device.type === DeviceType.Wifi ? "Wi-Fi" : device.name
            if (labels.indexOf(label) === -1) labels.push(label)
        }
        return labels.length > 0 ? labels.join(" + ") : "No connection"
    }
    readonly property string networkDetail: !networkConnected ? "Offline"
        : Networking.connectivity === NetworkConnectivity.Full ? "Internet access"
        : Networking.connectivity === NetworkConnectivity.Portal ? "Sign-in required"
        : Networking.connectivity === NetworkConnectivity.Limited ? "Limited connectivity"
        : Networking.connectivity === NetworkConnectivity.None ? "No internet"
        : "Connected"
    property real brightness: -1

    function refresh() {
        if (!status.running) status.running = true
    }

    function toggleWifi() {
        if (!wifiAvailable || wifiBlocked) return
        Networking.wifiEnabled = !Networking.wifiEnabled
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
            "backlight=$(find /sys/class/backlight -mindepth 1 -maxdepth 1 -type l 2>/dev/null | head -n1); "
                + "if [ -n \"$backlight\" ]; then current=$(cat \"$backlight/brightness\"); max=$(cat \"$backlight/max_brightness\"); b=$(awk -v c=\"$current\" -v m=\"$max\" 'BEGIN {printf \"%.0f\", 100*c/m}'); else b=-1; fi; "
                + "printf '%s\\n' \"$b\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const brightnessPercent = text.trim() === "" ? -1 : Number(text.trim())
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
