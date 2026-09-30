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
        property bool showDivider: false

        readonly property string rawLabel: BluetoothState.deviceLabel(device)
        readonly property bool unnamed: rawLabel === "Unknown device"
            || /^(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(rawLabel)
        readonly property string displayName: unnamed ? "Unnamed device" : rawLabel
        readonly property string address: String(device.address
            || (unnamed && rawLabel !== "Unknown device" ? rawLabel : "")).trim()
        readonly property bool canForget: (device.paired || device.trusted)
            && !device.connected && !BluetoothState.isBusy(device)

        width: parent.width
        height: unnamed && address !== "" ? 82 : 70
        color: device.connected ? (rowHover.hovered ? Theme.selectedHoverSurface : Theme.selectedSurface)
            : rowHover.hovered ? Theme.hoverSurface : "transparent"
        radius: Theme.radius

        HoverHandler { id: rowHover }

        Rectangle {
            id: deviceIcon
            anchors {
                left: parent.left
                leftMargin: Theme.spaceLg
                verticalCenter: parent.verticalCenter
            }
            width: 36
            height: 36
            radius: Theme.radius
            color: deviceRow.device.connected ? Theme.selectedSurface : Theme.surfaceRaised

            Text {
                anchors.centerIn: parent
                text: BluetoothState.deviceIcon(deviceRow.device)
                color: deviceRow.device.connected ? Theme.accent : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }
        }

        Column {
            anchors {
                left: deviceIcon.right
                leftMargin: Theme.spaceLg
                right: actions.left
                rightMargin: Theme.spaceMd
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.spaceXs

            Text {
                width: parent.width
                text: deviceRow.displayName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                visible: deviceRow.unnamed && deviceRow.address !== ""
                text: deviceRow.address
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: BluetoothState.statusText(deviceRow.device)
                color: deviceRow.device.connected ? Theme.accent : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                maximumLineCount: 1
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
                id: primaryAction
                width: 110
                height: Theme.compactControlSize
                selected: deviceRow.device.connected
                subtleSelected: true
                flat: true
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
                accessibleName: text + " " + deviceRow.displayName
                    + (deviceRow.unnamed ? ", " + deviceRow.address : "")
                toolTipText: accessibleName
                background: Rectangle {
                    color: primaryAction.down ? Theme.selectedPressedSurface
                        : primaryAction.hovered ? Theme.selectedHoverSurface
                        : primaryAction.enabled ? Theme.selectedSurface : Theme.surfaceRaised
                    border.color: Theme.focus
                    border.width: primaryAction.visualFocus ? Theme.focusWidth : 0
                    radius: Theme.radius
                }
                onClicked: root.activateDevice(deviceRow.device)
            }

            Item {
                width: 28
                height: Theme.compactControlSize

                ActionButton {
                    id: forgetAction
                    anchors.fill: parent
                    visible: deviceRow.canForget
                    opacity: rowHover.hovered || activeFocus ? 1 : 0.28
                    text: "󰆴"
                    flat: true
                    danger: hovered || activeFocus
                    accessibleName: "Forget " + deviceRow.displayName
                        + (deviceRow.unnamed ? ", " + deviceRow.address : "")
                    contentItem: Text {
                        text: forgetAction.text
                        color: forgetAction.danger ? Theme.danger : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: BluetoothState.forgetDevice(deviceRow.device)
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: Theme.spaceLg
                rightMargin: Theme.spaceLg
            }
            height: Theme.borderWidth
            color: Qt.alpha(Theme.border, 0.6)
            visible: deviceRow.showDivider
        }
    }

    component DeviceSection: Column {
        id: section

        required property string title
        required property var devices

        width: parent.width
        spacing: Theme.spaceMd
        visible: devices.length > 0

        Row {
            spacing: Theme.spaceMd

            Text {
                height: 24
                text: section.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: Math.max(24, deviceCount.implicitWidth + Theme.spaceLg)
                height: 24
                color: Theme.selectedSurface
                radius: Theme.radius

                Text {
                    id: deviceCount
                    anchors.centerIn: parent
                    text: section.devices.length
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            width: parent.width
            height: deviceRows.implicitHeight
            radius: Theme.radius
            color: Qt.alpha(Theme.surfaceRaised, 0.45)

            Column {
                id: deviceRows
                width: parent.width

                Repeater {
                    model: section.devices
                    DeviceRow {
                        required property var modelData
                        required property int index
                        device: modelData
                        showDivider: index < section.devices.length - 1
                    }
                }
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
                    border.width: powerSwitch.activeFocus ? Theme.focusWidth : 0
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
            visible: BluetoothState.available && (!BluetoothState.enabled || BluetoothState.blocked)
            text: BluetoothState.blocked ? "Bluetooth is blocked. Unblock the adapter to find devices."
                : "Enable Bluetooth to view paired and nearby devices"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        ScrollView {
            id: deviceScroll
            width: parent.width
            height: 360
            visible: BluetoothState.enabled
            clip: true
            contentWidth: availableWidth
            rightPadding: deviceScrollbar.visible ? deviceScrollbar.width + Theme.spaceMd : 0
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical: ScrollBar {
                id: deviceScrollbar
                policy: ScrollBar.AsNeeded
                visible: deviceScroll.contentHeight > deviceScroll.availableHeight
                width: 6
                padding: 0
                minimumSize: 0.12
                hoverEnabled: true

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: deviceScrollbar.pressed || deviceScrollbar.hovered
                        ? Theme.accent : Qt.alpha(Theme.textMuted, 0.7)
                }

                background: Rectangle {
                    color: Qt.alpha(Theme.border, 0.5)
                    radius: width / 2
                }
            }

            Column {
                width: deviceScroll.availableWidth
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

                Rectangle {
                    width: parent.width
                    height: 156
                    visible: !root.hasDevices
                    color: Qt.alpha(Theme.surfaceRaised, 0.45)
                    radius: Theme.radius

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Theme.spaceXl * 2
                        spacing: Theme.spaceMd

                        Text {
                            width: parent.width
                            text: "󰂯"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            width: parent.width
                            text: BluetoothState.discovering
                                ? "Scanning for nearby devices..."
                                : "No Bluetooth devices found"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: BluetoothState.discovering
                                ? "Keep your device nearby and in pairing mode."
                                : "Put your device in pairing mode, then select Scan."
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: errorText.implicitHeight + Theme.spaceLg * 2
            visible: root.actionError !== ""
            color: Theme.dangerSurface
            radius: Theme.radius

            Text {
                id: errorText
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Theme.spaceLg
                }
                text: root.actionError
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }
}
