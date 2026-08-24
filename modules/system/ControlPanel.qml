import QtQuick
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var audioState
    required property var systemState
    required property var controlState
    implicitWidth: 420
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
                    width: 48
                    height: 48
                    radius: 24
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
                    Text {
                        text: "Insaf"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                    }
                    Text {
                        text: "CPU " + root.systemState.cpuPercent + "%  ·  RAM " + root.systemState.memoryPercent + "%"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: Theme.spaceMd

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: (root.controlState.networkEnabled ? "󰤨  Wi-Fi on" : "󰤭  Wi-Fi off")
                    selected: root.controlState.networkEnabled
                    accessibleName: "Toggle Wi-Fi"
                    onClicked: root.controlState.toggleNetwork()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: (root.controlState.bluetoothEnabled ? "󰂯  Bluetooth on" : "󰂲  Bluetooth off")
                    selected: root.controlState.bluetoothEnabled
                    accessibleName: "Toggle Bluetooth"
                    onClicked: root.controlState.toggleBluetooth()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "󰸉  Wallpapers"
                    accessibleName: "Open wallpapers"
                    onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/Pictures/Wallpapers"])
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "󰄀  Screenshot"
                    accessibleName: "Take screenshot"
                    onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/Pictures/Screenshots\"; f=\"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\"; grim \"$f\" && wl-copy < \"$f\""])
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Text {
                text: root.audioState.outputUsable
                    ? "󰕾  " + String(root.audioState.output.description || root.audioState.output.name || "Output")
                        + "  ·  " + Math.round(root.audioState.outputVolume * 100) + "%"
                    : "󰖁  Audio unavailable"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    width: 58
                    text: root.audioState.outputMuted ? "󰝟" : "󰕾"
                    accessibleName: "Toggle output mute"
                    enabled: root.audioState.outputUsable
                    onClicked: root.audioState.toggleOutputMute()
                }
                ActionButton {
                    width: parent.width - 58 - parent.spacing
                    text: "Open audio devices"
                    accessibleName: "Open audio panel"
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
            }

            Rectangle { width: parent.width; height: 1; color: Theme.border }

            Row {
                width: parent.width
                spacing: Theme.spaceSm

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "󰌾"
                    accessibleName: "Lock"
                    onClicked: Quickshell.execDetached([
                        "swaylock", "-f", "-i",
                        Quickshell.env("HOME") + "/Pictures/Wallpapers/bisbiswas-a-summer-evening.png",
                        "-s", "fill"
                    ])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    text: "󰤄"
                    accessibleName: "Suspend"
                    onClicked: Quickshell.execDetached([
                        "sh", "-c",
                        "swaylock -f -i \"$HOME/Pictures/Wallpapers/bisbiswas-a-summer-evening.png\" -s fill & sleep 0.5; systemctl suspend"
                    ])
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
