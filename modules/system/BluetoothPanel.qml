pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Bluetooth
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator

    property bool startedDiscovery: false
    property string actionError: ""

    readonly property bool hasDevices: BluetoothState.connectedDevices.length > 0
        || BluetoothState.pairedDevices.length > 0
        || BluetoothState.availableDevices.length > 0

    implicitWidth: 500
    implicitHeight: frame.implicitHeight

    function startDiscovery() {
        if (!BluetoothState.enabled || BluetoothState.discovering) return
        if (!BluetoothState.setDiscovering(true)) return
        startedDiscovery = true
        discoveryTimer.restart()
    }

    function stopDiscovery() {
        discoveryTimer.stop()
        if (startedDiscovery && BluetoothState.discovering) BluetoothState.setDiscovering(false)
        startedDiscovery = false
    }

    function refreshDiscovery() {
        actionError = ""
        if (!BluetoothState.enabled) return
        stopDiscovery()
        Qt.callLater(function() { root.startDiscovery() })
    }

    function setPowerEnabled(enable) {
        actionError = ""
        if (!enable) stopDiscovery()
        BluetoothState.setEnabled(enable)
    }

    function activateDevice(device) {
        if (device.remembered) {
            refreshDiscovery()
            return
        }
        BluetoothState.activateDevice(device)
    }

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var device

        width: parent.width
        height: 58
        color: device.connected ? Theme.surfaceRaised : "transparent"
        border.color: device.connected ? Theme.accent : Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radius

        Text {
            id: deviceIcon
            anchors {
                left: parent.left
                leftMargin: Theme.spaceLg
                verticalCenter: parent.verticalCenter
            }
            text: BluetoothState.deviceIcon(deviceRow.device)
            color: deviceRow.device.connected ? Theme.accent : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
        }

        Column {
            anchors {
                left: deviceIcon.right
                leftMargin: Theme.spaceMd
                right: actions.left
                rightMargin: Theme.spaceMd
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.spaceXs

            Text {
                width: parent.width
                text: BluetoothState.deviceLabel(deviceRow.device)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: deviceRow.device.connected
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: BluetoothState.statusText(deviceRow.device)
                color: deviceRow.device.connected ? Theme.accentMuted : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }

        Row {
            id: actions
            anchors {
                right: parent.right
                rightMargin: Theme.spaceMd
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.spaceSm

            ActionButton {
                width: visible ? 34 : 0
                height: Theme.compactControlSize
                visible: (deviceRow.device.paired || deviceRow.device.trusted)
                    && !deviceRow.device.connected && !BluetoothState.isBusy(deviceRow.device)
                text: "󰆴"
                danger: true
                accessibleName: "Forget " + BluetoothState.deviceLabel(deviceRow.device)
                onClicked: BluetoothState.forgetDevice(deviceRow.device)
            }

            ActionButton {
                width: 98
                height: Theme.compactControlSize
                selected: deviceRow.device.connected
                enabled: !BluetoothState.isBusy(deviceRow.device) && !deviceRow.device.blocked
                text: {
                    if (deviceRow.device.pairing) return "Pairing..."
                    if (deviceRow.device.state === BluetoothDeviceState.Connecting) return "Connecting..."
                    if (deviceRow.device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting..."
                    if (deviceRow.device.connected) return "Disconnect"
                    if (deviceRow.device.paired || deviceRow.device.trusted) return "Connect"
                    if (deviceRow.device.remembered) return "Find"
                    return "Pair"
                }
                accessibleName: text + " " + BluetoothState.deviceLabel(deviceRow.device)
                onClicked: root.activateDevice(deviceRow.device)
            }
        }
    }

    component DeviceSection: Column {
        id: section

        required property string title
        required property var devices

        width: parent.width
        spacing: Theme.spaceSm
        visible: devices.length > 0

        Text {
            width: parent.width
            text: section.title.toUpperCase() + "  ·  " + section.devices.length
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            font.letterSpacing: 1
        }

        Repeater {
            model: section.devices
            DeviceRow {
                required property var modelData
                device: modelData
            }
        }
    }

    Timer {
        id: discoveryTimer
        interval: 10000
        repeat: false
        onTriggered: root.stopDiscovery()
    }

    Component.onCompleted: startDiscovery()
    Component.onDestruction: stopDiscovery()

    Connections {
        target: BluetoothState

        function onEnabledChanged() {
            if (BluetoothState.enabled) Qt.callLater(function() { root.startDiscovery() })
        }

        function onOperationFailed(message) {
            root.actionError = message
        }
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: frame
        width: parent.width
        title: "Bluetooth"
        onCloseRequested: root.coordinator.close("close-bluetooth")

        Row {
            width: parent.width
            spacing: Theme.spaceMd

            Switch {
                id: powerSwitch

                width: parent.width - scanButton.width - parent.spacing
                height: Theme.rowHeight
                checked: BluetoothState.enabled
                enabled: BluetoothState.available && !BluetoothState.blocked
                hoverEnabled: true
                text: !BluetoothState.available ? "󰂲  Bluetooth unavailable"
                    : BluetoothState.blocked ? "󰂲  Bluetooth blocked"
                    : BluetoothState.enabled ? "󰂯  Bluetooth enabled" : "󰂲  Bluetooth disabled"
                Accessible.name: "Bluetooth power"
                onToggled: root.setPowerEnabled(checked)

                indicator: Rectangle {
                    width: 48
                    height: 28
                    x: powerSwitch.width - width - Theme.spaceMd
                    y: (powerSwitch.height - height) / 2
                    radius: height / 2
                    color: powerSwitch.checked ? Theme.accent : Theme.surfaceRaised
                    border.color: powerSwitch.activeFocus ? Theme.focus
                        : powerSwitch.checked ? Theme.accent : Theme.borderInteractive
                    border.width: powerSwitch.activeFocus ? Theme.focusWidth : Theme.borderWidth

                    Rectangle {
                        width: 20
                        height: 20
                        x: powerSwitch.checked ? parent.width - width - 4 : 4
                        y: 4
                        radius: width / 2
                        color: powerSwitch.checked ? Theme.textOnAccent : Theme.textMuted

                        Behavior on x {
                            NumberAnimation { duration: 120 }
                        }
                    }
                }

                contentItem: Text {
                    text: powerSwitch.text
                    color: powerSwitch.enabled ? Theme.text : Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.bold: powerSwitch.checked
                    leftPadding: Theme.spaceLg
                    rightPadding: 48 + Theme.spaceLg * 2
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: powerSwitch.down || powerSwitch.hovered ? Theme.surfaceRaised : "transparent"
                    border.color: powerSwitch.activeFocus ? Theme.focus : Theme.borderInteractive
                    border.width: powerSwitch.activeFocus ? Theme.focusWidth : Theme.borderWidth
                    radius: Theme.radius
                }
            }

            ActionButton {
                id: scanButton
                width: 104
                height: Theme.rowHeight
                text: BluetoothState.discovering ? "Scanning..." : "Scan"
                selected: BluetoothState.discovering
                enabled: BluetoothState.enabled
                accessibleName: "Scan for Bluetooth devices"
                onClicked: root.refreshDiscovery()
            }
        }

        Text {
            width: parent.width
            visible: !BluetoothState.available
            text: "No Bluetooth adapter is available"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            visible: BluetoothState.available && !BluetoothState.enabled
            text: "Enable Bluetooth to view paired and nearby devices"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        ScrollView {
            width: parent.width
            height: 360
            visible: BluetoothState.enabled
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: parent.width
                spacing: Theme.spaceLg

                DeviceSection {
                    title: "Connected devices"
                    devices: BluetoothState.connectedDevices
                }

                DeviceSection {
                    title: "Paired devices"
                    devices: BluetoothState.pairedDevices
                }

                DeviceSection {
                    title: "Available devices"
                    devices: BluetoothState.availableDevices
                }

                Text {
                    width: parent.width
                    visible: !root.hasDevices
                    text: BluetoothState.discovering
                        ? "Scanning for nearby devices..."
                        : "No Bluetooth devices found"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spaceXl
                    wrapMode: Text.WordWrap
                }
            }
        }

        Text {
            width: parent.width
            visible: root.actionError !== ""
            text: root.actionError
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }
    }
}
