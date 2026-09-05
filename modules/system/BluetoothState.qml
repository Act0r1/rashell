pragma Singleton

import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: state

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool blocked: available && adapter.state === BluetoothAdapterState.Blocked
    readonly property bool discovering: available && adapter.discovering
    readonly property var devices: adapter && adapter.devices ? adapter.devices.values : []
    property var rememberedAvailableDevices: []
    readonly property var connectedDevices: sortedDevices(devices.filter(function(device) {
        return device && !device.blocked && device.connected
    }))
    readonly property var pairedDevices: sortedDevices(devices.filter(function(device) {
        return device && !device.blocked && !device.connected && (device.paired || device.trusted)
    }))
    readonly property var availableDevices: mergedAvailableDevices()

    signal operationFailed(string message)

    onDevicesChanged: rememberAvailableDevices()
    Component.onCompleted: rememberAvailableDevices()

    function sortedDevices(source) {
        const result = source.slice()
        result.sort(function(left, right) {
            return deviceLabel(left).localeCompare(deviceLabel(right))
        })
        return result
    }

    function deviceKey(device) {
        if (!device) return ""
        const address = String(device.address || "").trim()
        return address === "" ? deviceLabel(device) : address
    }

    function rememberedDevice(device) {
        return {
            address: String(device.address || ""),
            name: deviceLabel(device),
            icon: String(device.icon || ""),
            connected: false,
            paired: false,
            trusted: false,
            blocked: false,
            pairing: false,
            batteryAvailable: false,
            remembered: true
        }
    }

    function rememberAvailableDevices() {
        const remembered = ({})
        for (let index = 0; index < rememberedAvailableDevices.length; index++) {
            const device = rememberedAvailableDevices[index]
            remembered[deviceKey(device)] = device
        }

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index]
            if (!device) continue
            const key = deviceKey(device)
            if (device.blocked || device.connected || device.paired || device.trusted) {
                delete remembered[key]
            } else {
                remembered[key] = rememberedDevice(device)
            }
        }

        rememberedAvailableDevices = Object.keys(remembered).map(function(key) {
            return remembered[key]
        })
    }

    function mergedAvailableDevices() {
        const result = []
        const current = ({})
        for (let index = 0; index < devices.length; index++) {
            const device = devices[index]
            if (!device) continue
            current[deviceKey(device)] = true
            if (device.blocked || device.connected || device.paired || device.trusted) continue
            result.push(device)
        }
        for (let index = 0; index < rememberedAvailableDevices.length; index++) {
            const device = rememberedAvailableDevices[index]
            if (!current[deviceKey(device)]) result.push(device)
        }
        return sortedDevices(result)
    }

    function deviceLabel(device) {
        if (!device) return "Unknown device"
        const label = String(device.name || device.deviceName || "").trim()
        return label === "" ? String(device.address || "Unknown device") : label
    }

    function deviceIcon(device) {
        const hint = String((device ? device.icon : "") || "") + " " + deviceLabel(device)
        const normalized = hint.toLowerCase()
        if (normalized.indexOf("keyboard") !== -1) return "󰌌"
        if (normalized.indexOf("mouse") !== -1) return "󰍽"
        if (normalized.indexOf("headset") !== -1 || normalized.indexOf("headphone") !== -1) return "󰋋"
        if (normalized.indexOf("audio") !== -1 || normalized.indexOf("speaker") !== -1) return "󰓃"
        if (normalized.indexOf("phone") !== -1) return "󰏲"
        if (normalized.indexOf("gamepad") !== -1 || normalized.indexOf("controller") !== -1) return "󰖺"
        return "󰂯"
    }

    function batteryPercent(device) {
        if (!device || !device.batteryAvailable) return -1
        return Math.max(0, Math.min(100, Math.round(Number(device.battery) * 100)))
    }

    function isBusy(device) {
        return !!device && (device.pairing
            || device.state === BluetoothDeviceState.Connecting
            || device.state === BluetoothDeviceState.Disconnecting)
    }

    function statusText(device) {
        if (!device) return ""
        if (device.remembered) return "Previously discovered"
        if (device.pairing) return "Pairing"
        if (device.state === BluetoothDeviceState.Connecting) return "Connecting"
        if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting"

        const details = []
        if (device.connected) details.push("Connected")
        else if (device.paired || device.trusted) details.push("Paired")
        else details.push("Available")

        const battery = batteryPercent(device)
        if (battery >= 0) details.push("Battery " + battery + "%")
        return details.join("  ·  ")
    }

    function setEnabled(value) {
        if (!adapter || blocked) return false
        try {
            adapter.enabled = Boolean(value)
            return true
        } catch (error) {
            operationFailed("Could not change Bluetooth power")
            return false
        }
    }

    function toggleEnabled() {
        return setEnabled(!enabled)
    }

    function setDiscovering(value) {
        if (!adapter || !enabled) return false
        try {
            adapter.discovering = Boolean(value)
            return true
        } catch (error) {
            operationFailed("Could not scan for Bluetooth devices")
            return false
        }
    }

    function activateDevice(device) {
        if (!device || isBusy(device)) return
        try {
            if (device.connected) {
                device.disconnect()
            } else if (device.paired || device.trusted) {
                device.trusted = true
                device.connect()
            } else {
                device.pair()
            }
        } catch (error) {
            operationFailed("Bluetooth action failed for " + deviceLabel(device))
        }
    }

    function forgetDevice(device) {
        if (!device || device.connected || isBusy(device)) return
        try {
            device.trusted = false
            device.forget()
        } catch (error) {
            operationFailed("Could not forget " + deviceLabel(device))
        }
    }
}
