import QtQuick
import QtQuick.Dialogs
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var audioState
    required property var systemState
    required property var controlState
    required property var notificationState
    required property var configStore
    implicitWidth: 460
    implicitHeight: panel.implicitHeight
    property string armedAction: ""

    function confirmAction(action, command) {
        if (armedAction === action) {
            armedAction = ""
            Quickshell.execDetached(command)
            return
        }
        armedAction = action
        confirmationTimeout.restart()
    }

    Timer {
        id: confirmationTimeout
        interval: 3000
        onTriggered: root.armedAction = ""
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    FileDialog {
        id: wallpaperDialog
        title: "Choose wallpaper"
        currentFolder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            const selected = decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""))
            root.configStore.setWallpaper(selected)
        }
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "CONTROL CENTER"
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceLg

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                Rectangle {
                    width: 46
                    height: 46
                    radius: Theme.radius
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "I"
                        color: Theme.textOnAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 54
                    Text {
                        text: "Insaf"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                    }
                    Text {
                        text: "CPU " + root.systemState.cpuPercent + "%  ·  RAM " + root.systemState.memoryPercent
                            + "%  ·  " + root.systemState.updates + " updates  ·  " + root.configStore.theme
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }

            Text {
                text: "CONNECTIVITY"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: Theme.spaceMd

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: (root.controlState.networkEnabled ? "󰤨  Wi-Fi on" : "󰤭  Wi-Fi off")
                        + (root.controlState.networkName === "Not connected" ? "" : " · " + root.controlState.networkName)
                    selected: root.controlState.networkEnabled
                    accessibleName: "Toggle Wi-Fi"
                    onClicked: root.controlState.toggleNetwork()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: (root.controlState.bluetoothEnabled ? "󰂯  Bluetooth on" : "󰂲  Bluetooth off")
                        + (root.controlState.bluetoothDevice === "No connected device" ? "" : " · " + root.controlState.bluetoothDevice)
                    selected: root.controlState.bluetoothEnabled
                    accessibleName: "Toggle Bluetooth"
                    onClicked: root.controlState.toggleBluetooth()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "󰛳  Network settings"
                    accessibleName: "Open network settings"
                    onClicked: root.controlState.openNetworkSettings()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: root.notificationState.doNotDisturb ? "󰂛  DND on" : "󰂚  DND off"
                    selected: root.notificationState.doNotDisturb
                    accessibleName: "Toggle do not disturb"
                    onClicked: root.notificationState.doNotDisturb = !root.notificationState.doNotDisturb
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Text {
                text: "AUDIO"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.audioState.outputUsable
                    ? "󰕾  " + root.audioState.nodeLabel(root.audioState.output) + "  ·  " + Math.round(root.audioState.outputVolume * 100) + "%"
                    : "󰖁  Audio output unavailable"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                height: Theme.controlHeight
                spacing: Theme.spaceMd
                ActionButton {
                    width: 46
                    text: root.audioState.outputMuted ? "󰝟" : "󰕾"
                    accessibleName: "Toggle output mute"
                    enabled: root.audioState.outputUsable
                    onClicked: root.audioState.toggleOutputMute()
                }
                LevelSlider {
                    width: parent.width - 46 - parent.spacing
                    height: parent.height
                    enabled: root.audioState.outputUsable
                    value: root.audioState.outputVolume
                    accessibleName: "Output volume"
                    onMoved: root.audioState.setOutputVolume(value)
                }
            }

            Text {
                width: parent.width
                text: root.audioState.inputUsable
                    ? "󰍬  " + root.audioState.nodeLabel(root.audioState.input) + "  ·  " + Math.round(root.audioState.inputVolume * 100) + "%"
                    : "󰍭  Microphone unavailable"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                height: Theme.controlHeight
                spacing: Theme.spaceMd
                ActionButton {
                    width: 46
                    text: root.audioState.inputMuted ? "󰍭" : "󰍬"
                    accessibleName: "Toggle microphone mute"
                    enabled: root.audioState.inputUsable
                    onClicked: root.audioState.toggleInputMute()
                }
                LevelSlider {
                    width: parent.width - 46 - parent.spacing
                    height: parent.height
                    enabled: root.audioState.inputUsable
                    value: root.audioState.inputVolume
                    accessibleName: "Microphone volume"
                    onMoved: root.audioState.setInputVolume(value)
                }
            }

            ActionButton {
                width: parent.width
                text: "Open input and output devices"
                accessibleName: "Open audio devices"
                onClicked: {
                    root.coordinator.close("switch")
                    Qt.callLater(function() {
                        root.coordinator.toggleRegistered(
                            "audio",
                            Quickshell.shellDir + "/modules/audio/AudioPanel.qml",
                            { coordinator: root.coordinator, audioState: root.audioState }
                        )
                    })
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Column {
                width: parent.width
                visible: root.controlState.brightness >= 0
                spacing: Theme.spaceSm
                Text {
                    text: "BRIGHTNESS  ·  " + Math.round(root.controlState.brightness * 100) + "%"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                LevelSlider {
                    width: parent.width
                    height: Theme.controlHeight
                    from: 0.01
                    to: 1
                    value: root.controlState.brightness
                    accessibleName: "Display brightness"
                    onMoved: root.controlState.setBrightness(value)
                }
            }

            Text {
                text: "THEME"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceSm
                Repeater {
                    model: ["oilslick", "muninn", "nevermore", "talon"]
                    ActionButton {
                        required property string modelData
                        width: (parent.width - parent.spacing * 3) / 4
                        text: modelData
                        selected: root.configStore.theme === modelData
                        accessibleName: "Use " + modelData + " theme"
                        onClicked: root.configStore.setTheme(modelData)
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 3
                spacing: Theme.spaceMd
                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "󰸉  Wallpaper"
                    accessibleName: "Choose wallpaper"
                    onClicked: wallpaperDialog.open()
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "󰄀  Screenshot"
                    accessibleName: "Take screenshot"
                    onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/Pictures/Screenshots\"; f=\"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\"; grim \"$f\" && wl-copy < \"$f\""])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    text: "󰏔  Update " + root.systemState.updates
                    accessibleName: "Open system updater"
                    onClicked: Quickshell.execDetached(["ghostty", "-e", "bash", "-lc", "yay; flatpak update; read -n 1 -p 'Press any key to close'"])
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Row {
                width: parent.width
                spacing: Theme.spaceSm

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "󰌾"
                    accessibleName: "Lock"
                    onClicked: Quickshell.execDetached(["swaylock", "-f", "-i", root.configStore.wallpaperPath, "-s", "fill"])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "󰤄"
                    accessibleName: "Suspend"
                    onClicked: Quickshell.execDetached(["sh", "-c", "swaylock -f -i " + JSON.stringify(root.configStore.wallpaperPath) + " -s fill & sleep 0.5; systemctl suspend"])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: root.armedAction === "reboot" ? "CONFIRM" : "󰜉"
                    selected: root.armedAction === "reboot"
                    accessibleName: "Restart; activate twice to confirm"
                    onClicked: root.confirmAction("reboot", ["systemctl", "reboot"])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: root.armedAction === "poweroff" ? "CONFIRM" : "󰐥"
                    selected: root.armedAction === "poweroff"
                    accessibleName: "Power off; activate twice to confirm"
                    onClicked: root.confirmAction("poweroff", ["systemctl", "poweroff"])
                }
            }
        }
    }
}
