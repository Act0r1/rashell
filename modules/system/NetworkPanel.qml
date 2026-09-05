pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Networking
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator

    property var selectedNetwork: null
    property string password: ""
    property string networkError: ""
    property bool scannerWasEnabled: false

    readonly property var wifiDevice: {
        const devices = Networking.devices ? Networking.devices.values : []
        for (let index = 0; index < devices.length; index++) {
            if (devices[index].type === DeviceType.Wifi) return devices[index]
        }
        return null
    }

    readonly property var availableNetworks: {
        if (!wifiDevice || !wifiDevice.networks) return []

        const networks = wifiDevice.networks.values.slice()
        const strongestByName = ({})
        for (let index = 0; index < networks.length; index++) {
            const network = networks[index]
            if (!network || !network.name) continue
            const current = strongestByName[network.name]
            if (!current || network.connected || network.signalStrength > current.signalStrength) {
                strongestByName[network.name] = network
            }
        }

        const result = Object.keys(strongestByName).map(function(name) { return strongestByName[name] })
        result.sort(function(left, right) {
            if (left.connected !== right.connected) return left.connected ? -1 : 1
            return right.signalStrength - left.signalStrength
        })
        return result
    }

    readonly property var connectedNetwork: {
        for (let index = 0; index < availableNetworks.length; index++) {
            if (availableNetworks[index].connected) return availableNetworks[index]
        }
        return null
    }

    implicitWidth: 480
    implicitHeight: frame.implicitHeight

    function signalIcon(strength) {
        const percent = Math.round(Number(strength) * 100)
        if (percent >= 75) return "󰤨"
        if (percent >= 50) return "󰤥"
        if (percent >= 25) return "󰤢"
        return "󰤟"
    }

    function requiresPassword(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
    }

    function failureMessage(reason) {
        if (reason === ConnectionFailReason.NoSecrets) return "A password is required"
        if (reason === ConnectionFailReason.WifiAuthTimeout) return "Authentication timed out"
        if (reason === ConnectionFailReason.WifiNetworkLost) return "The network is no longer available"
        return "Could not connect to the network"
    }

    function activateNetwork(network) {
        if (!network || network.stateChanging) return
        networkError = ""

        if (network.connected) {
            network.disconnect()
            return
        }
        if (network.known || !requiresPassword(network)) {
            selectedNetwork = network
            network.connect()
            return
        }

        selectedNetwork = network
        password = ""
        passwordField.forceActiveFocus()
    }

    function connectSelected() {
        if (!selectedNetwork || selectedNetwork.stateChanging) return
        networkError = ""

        if (selectedNetwork.known || !requiresPassword(selectedNetwork)) {
            selectedNetwork.connect()
            return
        }
        if (password.length === 0) {
            networkError = "Enter the network password"
            passwordField.forceActiveFocus()
            return
        }

        selectedNetwork.connectWithPsk(password)
    }

    function refreshNetworks() {
        if (!wifiDevice) return
        wifiDevice.scannerEnabled = false
        Qt.callLater(function() {
            if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
        })
    }

    Component.onCompleted: {
        if (wifiDevice) {
            scannerWasEnabled = wifiDevice.scannerEnabled
            wifiDevice.scannerEnabled = true
        }
    }

    Component.onDestruction: {
        if (wifiDevice) wifiDevice.scannerEnabled = scannerWasEnabled
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: frame
        width: parent.width
        title: "Network"
        onCloseRequested: root.coordinator.close("close-network")

        Row {
            width: parent.width
            spacing: Theme.spaceMd

            ActionButton {
                width: parent.width - refreshButton.width - parent.spacing
                text: Networking.wifiEnabled ? "󰤨  Wi-Fi enabled" : "󰤭  Wi-Fi disabled"
                selected: Networking.wifiEnabled
                accessibleName: "Toggle Wi-Fi"
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }

            ActionButton {
                id: refreshButton
                width: 92
                text: "Refresh"
                accessibleName: "Refresh Wi-Fi networks"
                enabled: Networking.wifiEnabled && root.wifiDevice !== null
                onClicked: root.refreshNetworks()
            }
        }

        Text {
            width: parent.width
            visible: root.wifiDevice === null
            text: "No Wi-Fi adapter is available"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            visible: root.wifiDevice !== null && !Networking.wifiEnabled
            text: "Enable Wi-Fi to view nearby networks"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            width: parent.width
            visible: root.connectedNetwork !== null
            text: "CONNECTED  ·  " + (root.connectedNetwork ? root.connectedNetwork.name : "")
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            font.letterSpacing: 1
            elide: Text.ElideRight
        }

        ListView {
            id: networkList
            width: parent.width
            height: Math.min(contentHeight, Theme.rowHeight * 7)
            visible: Networking.wifiEnabled && root.wifiDevice !== null
            clip: true
            spacing: Theme.spaceXs
            boundsBehavior: Flickable.StopAtBounds
            model: root.availableNetworks

            delegate: ActionButton {
                id: networkButton
                required property var modelData

                width: ListView.view.width
                height: Theme.rowHeight
                selected: modelData.connected
                subtleSelected: true
                enabled: !modelData.stateChanging
                text: root.signalIcon(modelData.signalStrength) + "  " + modelData.name
                    + "  ·  " + Math.round(modelData.signalStrength * 100) + "%"
                    + (root.requiresPassword(modelData) ? "  " : "")
                    + (modelData.stateChanging ? "  ·  connecting" : "")
                accessibleName: modelData.name + ", " + Math.round(modelData.signalStrength * 100)
                    + " percent" + (modelData.connected ? ", connected" : "")
                onClicked: root.activateNetwork(modelData)

                Connections {
                    target: networkButton.modelData

                    function onConnectionFailed(reason) {
                        root.selectedNetwork = networkButton.modelData
                        root.password = ""
                        root.networkError = root.failureMessage(reason)
                    }

                    function onConnectedChanged() {
                        if (!networkButton.modelData.connected) return
                        root.selectedNetwork = null
                        root.password = ""
                        root.networkError = ""
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: Networking.wifiEnabled && root.wifiDevice !== null && root.availableNetworks.length === 0
            text: "Scanning for nearby networks..."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Column {
            width: parent.width
            visible: root.selectedNetwork !== null && root.selectedNetwork
                && !root.selectedNetwork.connected && root.requiresPassword(root.selectedNetwork)
            spacing: Theme.spaceMd

            Text {
                width: parent.width
                text: "PASSWORD  ·  " + (root.selectedNetwork ? root.selectedNetwork.name : "")
                color: Theme.accentMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                elide: Text.ElideRight
            }

            TextField {
                id: passwordField
                width: parent.width
                height: Theme.rowHeight
                text: root.password
                onTextChanged: root.password = text
                placeholderText: "Network password"
                echoMode: TextInput.Password
                color: Theme.text
                placeholderTextColor: Theme.textMuted
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                leftPadding: Theme.spaceLg
                rightPadding: Theme.spaceLg
                Accessible.name: "Password for " + (root.selectedNetwork ? root.selectedNetwork.name : "network")
                onAccepted: root.connectSelected()

                background: Rectangle {
                    color: Theme.surfaceRaised
                    border.color: passwordField.activeFocus ? Theme.focus : Theme.borderInteractive
                    border.width: passwordField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                    radius: Theme.radius
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Cancel"
                    accessibleName: "Cancel network connection"
                    onClicked: {
                        root.selectedNetwork = null
                        root.password = ""
                        root.networkError = ""
                    }
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: root.selectedNetwork && root.selectedNetwork.stateChanging ? "Connecting..." : "Connect"
                    selected: true
                    enabled: root.selectedNetwork !== null && !root.selectedNetwork.stateChanging
                    accessibleName: "Connect to " + (root.selectedNetwork ? root.selectedNetwork.name : "network")
                    onClicked: root.connectSelected()
                }
            }
        }

        Text {
            width: parent.width
            visible: root.networkError !== ""
            text: root.networkError
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }
    }
}
