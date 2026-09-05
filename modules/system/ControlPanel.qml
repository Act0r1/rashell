pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var audioState
    required property var screenshotState
    required property var systemState
    required property var controlState
    required property var notificationState
    required property var sessionModeState
    required property var textCaptureState
    required property var configStore
    required property var barEditor
    required property var lockScreen
    required property var wallpaperPicker
    required property string outputName

    readonly property var anchorWindow: coordinator.anchorItem ? coordinator.anchorItem.QsWindow.window : null
    readonly property var targetScreen: anchorWindow ? anchorWindow.screen : null
    readonly property real availablePanelHeight: {
        const anchor = coordinator.anchorItem
        const anchorBottom = anchorWindow && anchor
            ? anchorWindow.contentItem.mapFromItem(anchor, 0, anchor.height + Theme.panelGap).y
            : Theme.barHeight + Theme.panelGap
        return Math.max(240, (targetScreen ? targetScreen.height : 900)
            - Math.max(Theme.barHeight + Theme.panelGap, anchorBottom) - Theme.edgeMargin - Theme.spaceMd)
    }
    readonly property real frameChromeHeight: Math.max(Theme.compactControlSize, 36)
        + Theme.panelPadding * 2 + Theme.spaceLg * 4 + Theme.borderWidth * 2 + powerRow.height
    property string armedAction: ""

    implicitWidth: Math.min(460, targetScreen ? targetScreen.width - Theme.spaceXl * 2 : 460)
    implicitHeight: panel.implicitHeight

    function confirmAction(action, command) {
        if (armedAction === action) {
            armedAction = ""
            Quickshell.execDetached(command)
            return
        }
        armedAction = action
        confirmationTimeout.restart()
    }

    function openAudioDevices() {
        root.coordinator.open(
            "audio", root.coordinator.anchorItem, root.coordinator.alignment,
            Quickshell.shellDir + "/modules/audio/AudioPanel.qml",
            { coordinator: root.coordinator, audioState: root.audioState }
        )
    }

    function revealFocusedControl() {
        const window = root.Window.window
        const item = window ? window.activeFocusItem : null
        if (!item) return
        let ancestor = item
        while (ancestor && ancestor !== controls) ancestor = ancestor.parent
        if (!ancestor) return
        const top = controls.mapFromItem(item, 0, 0).y
        const bottom = top + item.height
        if (top < controlScroll.contentY) controlScroll.contentY = Math.max(0, top - Theme.spaceSm)
        else if (bottom > controlScroll.contentY + controlScroll.height) {
            controlScroll.contentY = Math.min(controlScroll.contentHeight - controlScroll.height,
                bottom - controlScroll.height + Theme.spaceSm)
        }
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

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() { root.revealFocusedControl() }
    }

    component QuickTile: Rectangle {
        id: tile

        required property string label
        required property string detail
        required property string glyph
        required property string accessibleName
        property string toggleName: ""
        property bool active: false
        property bool toggleEnabled: true
        property bool hasToggle: false
        readonly property bool hovered: tileAction.hovered || tileToggle.hovered
        signal activated()
        signal toggleRequested()

        height: 56
        radius: Theme.radius
        color: tileAction.down || tileToggle.down ? Qt.alpha(Theme.accent, 0.2)
            : tile.hovered ? Qt.alpha(Theme.accent, 0.14)
            : tile.active ? Qt.alpha(Theme.accent, 0.07) : Theme.surface
        border.color: tileAction.visualFocus || tileToggle.visualFocus ? Theme.focus
            : tile.hovered ? Theme.accentMuted : tile.active ? Theme.accentMuted : Theme.border
        border.width: tileAction.visualFocus || tileToggle.visualFocus ? Theme.focusWidth : Theme.borderWidth

        ActionButton {
            id: tileAction
            anchors {
                fill: parent
                rightMargin: tile.hasToggle ? 48 : 0
            }
            accessibleName: tile.accessibleName
            toolTipText: ""
            onClicked: tile.activated()
            leftPadding: Theme.spaceLg
            rightPadding: Theme.spaceSm
            topPadding: Theme.spaceMd
            bottomPadding: Theme.spaceMd

            contentItem: Row {
                spacing: Theme.spaceMd
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    text: tile.glyph
                    color: tile.active ? Theme.accent : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20 - parent.spacing
                    spacing: Theme.spaceSm
                    Text {
                        width: parent.width
                        text: tile.label
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: tile.detail
                        textFormat: Text.PlainText
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }
            }
            background: Item {}
        }

        Switch {
            id: tileToggle
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: Theme.spaceSm
            }
            visible: tile.hasToggle
            enabled: tile.toggleEnabled
            hoverEnabled: true
            width: 44
            padding: 0
            checked: tile.active
            Accessible.name: tile.toggleName
            onToggled: tile.toggleRequested()
            contentItem: Item {}
            background: Item {}
            indicator: Rectangle {
                x: (tileToggle.width - width) / 2
                y: (tileToggle.height - height) / 2
                width: 30
                height: 18
                radius: height / 2
                color: !tileToggle.enabled ? Theme.border
                    : tileToggle.checked ? Theme.accent : Theme.borderInteractive

                Rectangle {
                    x: tileToggle.checked ? parent.width - width - 3 : 3
                    y: 3
                    width: 12
                    height: 12
                    radius: width / 2
                    color: tileToggle.checked ? Theme.textOnAccent : Theme.surface
                }
            }
        }
    }

    component AudioControl: Column {
        id: audioControl

        required property string label
        required property string deviceName
        required property string glyph
        required property bool usable
        required property real volume
        signal muteRequested()
        signal volumeMoved(real value)

        spacing: Theme.spaceSm

        Item {
            width: parent.width
            height: Theme.compactControlSize

            ActionButton {
                id: deviceButton
                anchors {
                    left: parent.left
                    right: levelText.left
                    rightMargin: Theme.spaceMd
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height
                leftPadding: 0
                rightPadding: Theme.spaceSm
                accessibleName: "Choose " + audioControl.label.toLowerCase() + " device: " + audioControl.deviceName
                toolTipText: audioControl.deviceName + " · Choose device"
                onClicked: root.openAudioDevices()
                contentItem: Text {
                    text: audioControl.label + " · " + audioControl.deviceName + "  ›"
                    textFormat: Text.PlainText
                    color: deviceButton.hovered ? Theme.accent : audioControl.usable ? Theme.text : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "transparent"
                    radius: Theme.radius
                    border.color: deviceButton.activeFocus ? Theme.focus : "transparent"
                    border.width: Theme.focusWidth
                }
            }

            Text {
                id: levelText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: audioControl.usable ? Math.round(audioControl.volume * 100) + "%" : "—"
                color: audioControl.usable ? Theme.text : Theme.textDisabled
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }

        Row {
            width: parent.width
            height: Theme.controlHeight
            spacing: Theme.spaceMd

            ActionButton {
                width: 40
                height: parent.height
                text: audioControl.glyph
                accessibleName: "Toggle " + audioControl.label.toLowerCase() + " mute"
                enabled: audioControl.usable
                onClicked: audioControl.muteRequested()
            }
            LevelSlider {
                width: parent.width - 40 - parent.spacing
                height: parent.height
                enabled: audioControl.usable
                value: audioControl.volume
                accessibleName: audioControl.label + " volume"
                onMoved: audioControl.volumeMoved(value)
            }
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

            Flickable {
                id: controlScroll
                width: parent.width
                height: Math.min(contentHeight, Math.max(80, root.availablePanelHeight - root.frameChromeHeight))
                contentWidth: width
                contentHeight: controls.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ScrollBar.vertical: ScrollBar {
                    id: controlScrollbar
                    policy: ScrollBar.AsNeeded
                    visible: controlScroll.contentHeight > controlScroll.height
                    width: 5
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: 2
                        color: controlScrollbar.pressed || controlScrollbar.hovered ? Theme.accent : Theme.accentMuted
                    }
                    background: Item {}
                }

                Column {
                    id: controls
                    width: parent.width - (controlScroll.contentHeight > controlScroll.height ? Theme.spaceMd : 0)
                    spacing: Theme.spaceLg

                    Row {
                        width: parent.width
                        spacing: Theme.spaceMd

                        Rectangle {
                            width: 40
                            height: 40
                            radius: Theme.radius
                            color: Theme.surfaceRaised
                            border.color: Theme.accentMuted
                            border.width: Theme.borderWidth
                            Text {
                                anchors.centerIn: parent
                                text: "I"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                font.bold: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 48
                            spacing: Theme.spaceSm
                            Text {
                                text: "Insaf"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                text: "CPU " + root.systemState.cpuPercent + "%  ·  RAM " + root.systemState.memoryPercent + "%"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spaceMd

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: Theme.radius
                            color: Theme.surfaceRaised

                            Text {
                                id: connectionGlyph
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spaceLg
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                text: root.controlState.wiredConnected ? "󰈀"
                                    : root.controlState.networkConnected ? "󰤨" : "󰤭"
                                color: root.controlState.networkConnected ? Theme.accent : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                anchors.left: connectionGlyph.right
                                anchors.leftMargin: Theme.spaceMd
                                anchors.right: connectionDetail.left
                                anchors.rightMargin: Theme.spaceMd
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.controlState.networkLabel
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                id: connectionDetail
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spaceLg
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.controlState.networkDetail
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: Theme.spaceMd

                            QuickTile {
                                width: (parent.width - parent.spacing) / 2
                                label: "Wi-Fi"
                                detail: root.controlState.wifiDetail
                                glyph: root.controlState.wifiEnabled ? "󰤨" : "󰤭"
                                active: root.controlState.wifiEnabled
                                accessibleName: "Choose Wi-Fi network"
                                hasToggle: true
                                toggleEnabled: root.controlState.wifiAvailable && !root.controlState.wifiBlocked
                                toggleName: "Turn Wi-Fi " + (root.controlState.wifiEnabled ? "off" : "on")
                                onToggleRequested: root.controlState.toggleWifi()
                                onActivated: root.coordinator.open(
                                    "network", root.coordinator.anchorItem, root.coordinator.alignment,
                                    Quickshell.shellDir + "/modules/system/NetworkPanel.qml",
                                    { coordinator: root.coordinator }
                                )
                            }

                            QuickTile {
                                width: (parent.width - parent.spacing) / 2
                                label: "Bluetooth"
                                detail: !BluetoothState.available ? "Unavailable" : BluetoothState.blocked ? "Blocked"
                                    : !BluetoothState.enabled ? "Off" : BluetoothState.connectedDevices.length > 0
                                        ? BluetoothState.deviceLabel(BluetoothState.connectedDevices[0]) : "Not connected"
                                glyph: BluetoothState.enabled ? "󰂯" : "󰂲"
                                active: BluetoothState.enabled
                                toggleEnabled: BluetoothState.available && !BluetoothState.blocked
                                accessibleName: "Open Bluetooth devices"
                                hasToggle: true
                                toggleName: "Turn Bluetooth " + (BluetoothState.enabled ? "off" : "on")
                                onToggleRequested: BluetoothState.toggleEnabled()
                                onActivated: root.coordinator.open(
                                    "bluetooth", root.coordinator.anchorItem, root.coordinator.alignment,
                                    Quickshell.shellDir + "/modules/system/BluetoothPanel.qml",
                                    { coordinator: root.coordinator }
                                )
                            }

                            QuickTile {
                                width: (parent.width - parent.spacing) / 2
                                label: "Mode"
                                detail: root.sessionModeState.title + "  ›"
                                glyph: "󰓅"
                                active: root.sessionModeState.active
                                accessibleName: "Choose work or presentation mode"
                                onActivated: root.coordinator.open(
                                    "modes", root.coordinator.anchorItem, root.coordinator.alignment,
                                    Quickshell.shellDir + "/modules/session/ModePanel.qml",
                                    { coordinator: root.coordinator, modeState: root.sessionModeState }
                                )
                            }

                            QuickTile {
                                width: (parent.width - parent.spacing) / 2
                                label: "Do not disturb"
                                detail: root.notificationState.doNotDisturb ? "On · Paused" : "Off · Notifications on"
                                glyph: root.notificationState.doNotDisturb ? "󰂛" : "󰂚"
                                active: root.notificationState.doNotDisturb
                                accessibleName: "Turn do not disturb " + (root.notificationState.doNotDisturb ? "off" : "on")
                                onActivated: root.notificationState.doNotDisturb = !root.notificationState.doNotDisturb
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: Theme.borderWidth; color: Theme.border }

                    Column {
                        width: parent.width
                        spacing: Theme.spaceMd

                        AudioControl {
                            width: parent.width
                            label: "Speakers"
                            deviceName: root.audioState.outputUsable ? root.audioState.nodeLabel(root.audioState.output) : "Unavailable"
                            glyph: root.audioState.outputMuted ? "󰝟" : "󰕾"
                            usable: root.audioState.outputUsable
                            volume: root.audioState.outputVolume
                            onMuteRequested: root.audioState.toggleOutputMute()
                            onVolumeMoved: value => root.audioState.setOutputVolume(value)
                        }

                        AudioControl {
                            width: parent.width
                            label: "Microphone"
                            deviceName: root.audioState.inputUsable ? root.audioState.nodeLabel(root.audioState.input) : "Unavailable"
                            glyph: root.audioState.inputMuted ? "󰍭" : "󰍬"
                            usable: root.audioState.inputUsable
                            volume: root.audioState.inputVolume
                            onMuteRequested: root.audioState.toggleInputMute()
                            onVolumeMoved: value => root.audioState.setInputVolume(value)
                        }
                    }

                    Column {
                        width: parent.width
                        visible: root.controlState.brightness >= 0
                        spacing: Theme.spaceSm
                        Text {
                            text: "Brightness  ·  " + Math.round(root.controlState.brightness * 100) + "%"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
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

                    Row {
                        width: parent.width
                        spacing: Theme.spaceMd
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            height: 38
                            text: root.textCaptureState.recording ? "● Recording…" : "󰍬  Text & dictation"
                            selected: root.textCaptureState.recording
                            accessibleName: "Open text capture and dictation"
                            onClicked: root.coordinator.open(
                                "text", root.coordinator.anchorItem, root.coordinator.alignment,
                                Quickshell.shellDir + "/modules/capture/TextCapturePanel.qml",
                                { coordinator: root.coordinator, captureState: root.textCaptureState }
                            )
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            height: 38
                            text: "󰄀  Capture"
                            accessibleName: "Open screen capture"
                            onClicked: root.coordinator.open(
                                "screenshot", root.coordinator.anchorItem, root.coordinator.alignment,
                                Quickshell.shellDir + "/modules/system/ScreenshotPanel.qml",
                                {
                                    coordinator: root.coordinator, captureState: root.screenshotState,
                                    configStore: root.configStore, outputName: root.outputName
                                }
                            )
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spaceMd

                        ActionButton {
                            id: appearanceButton
                            width: parent.width
                            height: 38
                            leftPadding: Theme.spaceLg
                            rightPadding: Theme.spaceLg
                            accessibleName: "Open appearance settings"
                            onClicked: root.coordinator.appearanceRequested(root.targetScreen)
                            contentItem: Row {
                                spacing: Theme.spaceMd
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - appearanceStatus.implicitWidth - parent.spacing
                                    text: "󰏘  Appearance"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: appearanceStatus
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Theme.themeInfo(root.configStore.theme).name + "  ›"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spaceMd
                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                height: 36
                                text: "󰸉  Wallpaper"
                                accessibleName: "Choose wallpaper"
                                onClicked: {
                                    const screen = root.targetScreen
                                    const picker = root.wallpaperPicker
                                    root.coordinator.close("open-wallpaper")
                                    picker.open(screen)
                                }
                            }
                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                height: 36
                                text: "󰓡  Customize bar"
                                accessibleName: "Open bar settings"
                                onClicked: {
                                    const screen = root.targetScreen
                                    const editor = root.barEditor
                                    root.coordinator.close("open-bar-settings")
                                    editor.open(screen)
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spaceMd
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            height: 36
                            text: "󰏔  Updates"
                            accessibleName: "Open system updates"
                            onClicked: root.coordinator.open(
                                "updates", root.coordinator.anchorItem, root.coordinator.alignment,
                                Quickshell.shellDir + "/modules/system/UpdatesPanel.qml",
                                { coordinator: root.coordinator, systemState: root.systemState }
                            )
                        }
                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            height: 36
                            text: "󰻠  System details"
                            accessibleName: "Open system monitor"
                            onClicked: root.coordinator.open(
                                "system", root.coordinator.anchorItem, root.coordinator.alignment,
                                Quickshell.shellDir + "/modules/system/SystemPanel.qml",
                                { coordinator: root.coordinator, systemState: root.systemState }
                            )
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: Theme.borderWidth; color: Theme.border }

            Row {
                id: powerRow
                width: parent.width
                height: 40
                spacing: Theme.spaceSm

                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    height: parent.height
                    text: "󰌾  Lock"
                    accessibleName: "Lock screen"
                    onClicked: {
                        const lock = root.lockScreen
                        root.coordinator.close("lock-screen")
                        lock.lock()
                    }
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    height: parent.height
                    text: "󰤄  Sleep"
                    accessibleName: "Lock the screen and suspend"
                    onClicked: {
                        const lock = root.lockScreen
                        root.coordinator.close("suspend")
                        lock.lockAndSuspend()
                    }
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    height: parent.height
                    text: root.armedAction === "reboot" ? "CONFIRM" : "󰜉  Restart"
                    selected: root.armedAction === "reboot"
                    accessibleName: "Restart; click twice to confirm"
                    onClicked: root.confirmAction("reboot", ["systemctl", "reboot"])
                }
                ActionButton {
                    width: (parent.width - parent.spacing * 3) / 4
                    height: parent.height
                    text: root.armedAction === "poweroff" ? "CONFIRM" : "󰐥  Power"
                    selected: root.armedAction === "poweroff"
                    danger: true
                    accessibleName: "Power off; click twice to confirm"
                    onClicked: root.confirmAction("poweroff", ["systemctl", "poweroff"])
                }
            }
        }
    }
}
