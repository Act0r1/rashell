pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.bar
import qs.ui

Item {
    id: root

    required property var configStore
    required property var workspaceState
    required property var clockState
    required property var weatherState
    required property var audioState
    required property var mediaState
    required property var screenshotState
    required property var systemState
    required property var keyboardState
    required property var controlState
    required property var tokenState
    required property var notificationState
    required property var sessionState
    required property var textCaptureState
    required property var barEditor
    required property var lockScreen
    required property var wallpaperPicker
    required property var coordinator
    required property var osd
    required property var feedback
    property bool active: true
    property var focusWorkspaces: []

    signal controlRequested()
    signal toggleRequested(string outputName)

    component IslandModule: ModuleSlot {
        configStore: root.configStore
        workspaceState: root.workspaceState
        clockState: root.clockState
        weatherState: root.weatherState
        audioState: root.audioState
        mediaState: root.mediaState
        screenshotState: root.screenshotState
        systemState: root.systemState
        keyboardState: root.keyboardState
        controlState: root.controlState
        tokenState: root.tokenState
        notificationState: root.notificationState
        sessionState: root.sessionState
        textCaptureState: root.textCaptureState
        barEditor: root.barEditor
        lockScreen: root.lockScreen
        wallpaperPicker: root.wallpaperPicker
        coordinator: root.coordinator
        osd: root.osd
        feedback: root.feedback
        scale: press.active ? 0.98 : 1

        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

        PointHandler { id: press }
    }

    component CardSection: Item {
        id: section

        required property bool revealed
        required property int index

        opacity: revealed ? 1 : 0
        scale: 0.96 + opacity * 0.04
        enabled: revealed

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: section.revealed ? section.index * 30 : 0 }
                NumberAnimation { duration: Theme.motionSurface }
            }
        }
    }

    Variants {
        model: root.active ? Quickshell.screens : []

        delegate: Component {
            PanelWindow {
                id: islandWindow

                required property var modelData
                property bool expanded: false
                readonly property bool hostsPanels: true
                property var grabWindows: []
                readonly property bool panelOpen: root.coordinator.opened && root.coordinator.hosted
                    && root.coordinator.anchorItem !== null
                    && root.coordinator.anchorItem.QsWindow.window === islandWindow
                readonly property real idleHeight: Theme.controlHeight - Theme.spaceSm
                readonly property real cardWidth: Math.min(720, width - Theme.panelGap * 2)
                readonly property var activeWorkspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
                readonly property bool fullscreenActive: (activeWorkspace?.hasFullscreen ?? false)
                    || root.focusWorkspaces.includes(activeWorkspace?.id ?? -1)

                screen: modelData
                implicitWidth: Math.min(760, modelData.width)
                implicitHeight: modelData.height
                anchors.top: true
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region { item: hoverRegion }
                WlrLayershell.namespace: "rashell-island"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                onExpandedChanged: {
                    if (expanded) {
                        islandSurface.forceActiveFocus()
                        return
                    }
                    grabWindows.forEach(window => window.visible = false)
                    if (panelOpen) root.coordinator.close("island-collapse")
                }

                onPanelOpenChanged: {
                    if (panelOpen) {
                        panelClear.stop()
                        panelLoader.setSource(root.coordinator.contentSource, root.coordinator.contentProperties)
                        if (panelLoader.item) panelLoader.item.forceActiveFocus()
                    } else {
                        panelClear.restart()
                        if (expanded) islandSurface.forceActiveFocus()
                    }
                }

                Timer {
                    id: panelClear
                    interval: Theme.motionSurface
                    onTriggered: panelLoader.source = ""
                }

                IdleInhibitor {
                    window: islandWindow
                    enabled: root.sessionState.keepAwake
                }

                HyprlandFocusGrab {
                    windows: [islandWindow].concat(islandWindow.grabWindows)
                    active: islandWindow.expanded
                    onCleared: islandWindow.expanded = false
                }

                Connections {
                    target: root

                    function onToggleRequested(outputName) {
                        if (outputName === islandWindow.modelData.name) islandWindow.expanded = !islandWindow.expanded
                    }
                }

                Connections {
                    target: root.coordinator

                    function onOpenedChanged() {
                        if (islandWindow.panelOpen) islandWindow.expanded = true
                    }
                }

                Item {
                    id: hoverRegion
                    x: islandSurface.x
                    y: 0
                    width: islandSurface.width
                    height: islandSurface.height + islandSurface.y - y
                    z: 2

                    HoverHandler { id: islandHover }

                    MouseArea {
                        width: parent.width
                        height: islandSurface.y
                        enabled: !islandWindow.expanded
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) root.controlRequested()
                            else islandWindow.expanded = true
                        }
                    }
                }

                Rectangle {
                    id: islandSurface

                    x: (islandWindow.width - width) / 2
                    y: Theme.spaceSm
                    readonly property bool showsPanel: islandWindow.panelOpen && panelLoader.item !== null

                    width: showsPanel ? panelLoader.item.implicitWidth
                        : islandWindow.expanded ? islandWindow.cardWidth : idleClock.width + Theme.spaceXl * 2
                    height: showsPanel ? panelLoader.item.implicitHeight
                        : islandWindow.expanded ? card.implicitHeight + Theme.panelPadding * 2 : islandWindow.idleHeight
                    radius: showsPanel ? Theme.radius : islandWindow.expanded ? Theme.radius * 2 : height / 2
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: Theme.borderWidth
                    clip: true
                    opacity: !islandWindow.fullscreenActive || islandHover.hovered || islandWindow.expanded ? 1 : 0
                    scale: 0.96 + opacity * 0.04
                    focus: islandWindow.expanded

                    Keys.onEscapePressed: function(event) {
                        islandWindow.expanded = false
                        event.accepted = true
                    }

                    Behavior on width { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
                    Behavior on height { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
                    Behavior on radius { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
                    Behavior on opacity { NumberAnimation { duration: Theme.motionSurface; easing.type: Theme.motionEasing } }

                    Component.onCompleted: root.coordinator.registerAnchor("shell", islandWindow.modelData.name, islandSurface, "center")
                    Component.onDestruction: root.coordinator.unregisterAnchor("shell", islandWindow.modelData.name, islandSurface)

                    Row {
                        id: idleClock
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (islandWindow.idleHeight - height) / 2
                        z: 1
                        opacity: islandWindow.expanded ? 0 : 1

                        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }

                        Text {
                            id: idleHours
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(root.clockState.now, "HH:mm")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Theme.fontWeightStrong
                        }

                        Text {
                            anchors.baseline: idleHours.baseline
                            text: Qt.formatDateTime(root.clockState.now, ":ss")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Theme.fontWeightStrong
                        }

                        Item {
                            id: stopRecording
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.screenshotState.recording
                            width: stopContent.implicitWidth + Theme.spaceSm
                            height: islandWindow.idleHeight

                            Accessible.role: Accessible.Button
                            Accessible.name: "Stop screen recording"

                            Row {
                                id: stopContent
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spaceMd

                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.spaceMd + Theme.spaceXs
                                    height: 14

                                    Rectangle {
                                        anchors.right: parent.right
                                        width: Theme.borderWidth
                                        height: parent.height
                                        color: Theme.border
                                    }
                                }

                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: Theme.danger
                                        opacity: stopArea.containsMouse ? 0 : 1

                                        SequentialAnimation on opacity {
                                            running: root.screenshotState.recording && !stopArea.containsMouse
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 2
                                        color: Theme.danger
                                        opacity: stopArea.containsMouse ? 1 : 0
                                        scale: stopArea.containsMouse ? 1 : 0.4

                                        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
                                        Behavior on scale { NumberAnimation { duration: Theme.motionFast } }
                                    }
                                }

                                Text {
                                    readonly property int seconds: root.screenshotState.elapsedSeconds
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (seconds < 600 ? "0" : "") + Math.floor(seconds / 60) + ":"
                                        + (seconds % 60 < 10 ? "0" : "") + seconds % 60
                                    color: Theme.danger
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Theme.fontWeightStrong
                                }
                            }

                            MouseArea {
                                id: stopArea
                                anchors.fill: parent
                                enabled: !islandWindow.expanded
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.screenshotState.stop()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !islandWindow.expanded
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) root.controlRequested()
                            else islandWindow.expanded = true
                        }
                    }

                    Column {
                        id: card
                        x: (parent.width - width) / 2
                        y: Theme.panelPadding
                        width: islandWindow.cardWidth - Theme.panelPadding * 2
                        spacing: Theme.spaceLg
                        enabled: islandWindow.expanded && !islandWindow.panelOpen

                        CardSection {
                            width: parent.width
                            height: Math.max(headerClock.height, headerDetails.height)
                            revealed: islandWindow.expanded && !islandWindow.panelOpen
                            index: 0

                            Row {
                                id: headerClock

                                Text {
                                    id: hours
                                    text: Qt.formatDateTime(root.clockState.now, "HH:mm")
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontDisplay
                                    font.weight: Theme.fontWeightStrong
                                }

                                Text {
                                    anchors.baseline: hours.baseline
                                    text: Qt.formatDateTime(root.clockState.now, ":ss")
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontDisplay
                                    font.weight: Theme.fontWeightStrong
                                }

                                TapHandler {
                                    onTapped: islandWindow.expanded = false
                                }

                                Component.onCompleted: root.coordinator.registerAnchor("calendar", islandWindow.modelData.name, headerClock, "center")
                                Component.onDestruction: root.coordinator.unregisterAnchor("calendar", islandWindow.modelData.name, headerClock)
                            }

                            Column {
                                id: headerDetails
                                anchors.right: parent.right
                                spacing: Theme.spaceSm

                                IslandModule {
                                    anchors.right: parent.right
                                    moduleId: "rashell.weather"
                                    outputName: islandWindow.modelData.name
                                }

                                Text {
                                    id: headerDate
                                    text: Qt.formatDateTime(root.clockState.now, "dddd, dd MMMM")
                                    color: dateArea.containsMouse ? Theme.text : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody

                                    MouseArea {
                                        id: dateArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.coordinator.toggle(
                                            "calendar",
                                            headerDate,
                                            "center",
                                            Quickshell.shellDir + "/modules/clock/CalendarPanel.qml",
                                            { coordinator: root.coordinator, clockState: root.clockState }
                                        )
                                    }
                                }
                            }
                        }

                        CardSection {
                            width: parent.width
                            height: activityRow.implicitHeight
                            revealed: islandWindow.expanded && !islandWindow.panelOpen
                            index: 1

                            RowLayout {
                                id: activityRow
                                width: parent.width
                                spacing: Theme.spaceLg

                                Rectangle {
                                    id: mediaTile

                                    readonly property var media: root.mediaState
                                    readonly property real progress: media.length > 0
                                        ? Math.max(0, Math.min(1, media.position / media.length)) : 0

                                    function formatTime(seconds) {
                                        const total = Math.max(0, Math.floor(Number(seconds) || 0))
                                        return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0")
                                    }

                                    Layout.fillWidth: true
                                    implicitHeight: Theme.controlHeight + Theme.panelPadding * 2
                                    color: tileArea.containsMouse ? Qt.lighter(Theme.surfaceRaised, 1.12) : Theme.surfaceRaised
                                    radius: Theme.radius
                                    scale: tileArea.pressed ? 0.985 : 1

                                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                                    Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

                                    Component.onCompleted: root.coordinator.registerAnchor("media", islandWindow.modelData.name, mediaTile, "center")
                                    Component.onDestruction: root.coordinator.unregisterAnchor("media", islandWindow.modelData.name, mediaTile)

                                    Timer {
                                        interval: 1000
                                        repeat: true
                                        running: islandWindow.expanded && mediaTile.media.playing
                                        onTriggered: if (mediaTile.media.player) mediaTile.media.player.positionChanged()
                                    }

                                    Item {
                                        id: progressFill
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * mediaTile.progress
                                        visible: mediaTile.media.available
                                        clip: true

                                        Behavior on width { NumberAnimation { duration: 1000 } }

                                        Rectangle {
                                            width: parent.width + Theme.radius
                                            height: parent.height
                                            radius: Theme.radius
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.02) }
                                                GradientStop { position: 0.85; color: Qt.alpha(Theme.accent, 0.10) }
                                                GradientStop { position: 1; color: Qt.alpha(Theme.accent, 0.22) }
                                            }
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.radius
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 2
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.1) }
                                                GradientStop { position: 1; color: Theme.accent }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: tileArea

                                        readonly property bool overTitle: {
                                            const point = mapToItem(metaColumn, mouseX, mouseY)
                                            return point.x >= 0 && point.y >= 0 && point.y <= metaColumn.height
                                                && point.x <= Math.max(titleText.contentWidth, artistText.contentWidth)
                                        }

                                        anchors.fill: parent
                                        enabled: mediaTile.media.available
                                        hoverEnabled: true
                                        cursorShape: Qt.ArrowCursor
                                        onClicked: function(mouse) {
                                            if (!overTitle && mediaTile.media.length > 0) {
                                                mediaTile.media.seek(mouse.x / width)
                                                return
                                            }
                                            root.coordinator.toggle(
                                                "media",
                                                mediaTile,
                                                "center",
                                                Quickshell.shellDir + "/modules/media/MediaPanel.qml",
                                                { coordinator: root.coordinator, mediaState: mediaTile.media }
                                            )
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.panelPadding
                                        anchors.rightMargin: Theme.spaceMd + Theme.spaceXs
                                        spacing: Theme.spaceLg
                                        visible: mediaTile.media.available

                                        Item {
                                            implicitWidth: 13
                                            implicitHeight: 14

                                            Repeater {
                                                model: [900, 700, 1100]

                                                Rectangle {
                                                    id: eqBar
                                                    required property int modelData
                                                    required property int index
                                                    x: index * 5
                                                    anchors.bottom: parent.bottom
                                                    width: 3
                                                    height: 6
                                                    radius: 1.5
                                                    color: Theme.accent

                                                    SequentialAnimation on height {
                                                        running: islandWindow.expanded && mediaTile.media.playing
                                                        loops: Animation.Infinite
                                                        NumberAnimation { to: 14; duration: eqBar.modelData; easing.type: Easing.InOutSine }
                                                        NumberAnimation { to: 3; duration: eqBar.modelData; easing.type: Easing.InOutSine }
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            id: metaColumn
                                            Layout.fillWidth: true
                                            spacing: 0

                                            Text {
                                                id: titleText
                                                width: parent.width
                                                text: mediaTile.media.title
                                                color: Theme.text
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontBody
                                                font.weight: Font.Medium
                                            }

                                            Text {
                                                id: artistText
                                                width: parent.width
                                                visible: text !== ""
                                                text: mediaTile.media.artist
                                                color: Theme.textMuted
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSmall
                                            }
                                        }

                                        Row {
                                            visible: mediaTile.media.length > 0

                                            Text {
                                                text: mediaTile.formatTime(mediaTile.media.position)
                                                color: Theme.textMuted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                text: " / " + mediaTile.formatTime(mediaTile.media.length)
                                                color: Theme.textDisabled
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                            }
                                        }

                                        Row {
                                            spacing: Theme.spaceXs

                                            Repeater {
                                                model: [
                                                    { icon: "skip-back", primary: false },
                                                    { icon: "play", primary: true },
                                                    { icon: "skip-forward", primary: false }
                                                ]

                                                Rectangle {
                                                    id: mediaButton
                                                    required property var modelData
                                                    required property int index
                                                    readonly property bool primary: modelData.primary

                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: primary ? 36 : 32
                                                    height: width
                                                    radius: width / 2
                                                    color: Qt.alpha(Theme.text, buttonArea.containsMouse ? (primary ? 0.16 : 0.08) : (primary ? 0.10 : 0))
                                                    scale: buttonArea.pressed ? 0.9 : 1

                                                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                                                    Behavior on scale { NumberAnimation { duration: Theme.motionFast } }

                                                    ShellIcon {
                                                        anchors.centerIn: parent
                                                        width: 16
                                                        height: 16
                                                        name: mediaButton.primary ? (mediaTile.media.playing ? "pause" : "play") : mediaButton.modelData.icon
                                                        tint: mediaButton.primary || buttonArea.containsMouse ? Theme.text : Theme.textMuted
                                                    }

                                                    MouseArea {
                                                        id: buttonArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (mediaButton.index === 0) mediaTile.media.previous()
                                                            else if (mediaButton.primary) mediaTile.media.playPause()
                                                            else mediaTile.media.next()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !root.mediaState.available
                                        text: "Nothing playing"
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                    }
                                }

                                Rectangle {
                                    implicitWidth: workspaces.implicitWidth + Theme.panelPadding * 2
                                    implicitHeight: Theme.controlHeight + Theme.panelPadding * 2
                                    color: Theme.surfaceRaised
                                    radius: Theme.radius

                                    IslandModule {
                                        id: workspaces
                                        anchors.centerIn: parent
                                        moduleId: "rashell.workspaces"
                                        outputName: islandWindow.modelData.name
                                    }
                                }
                            }
                        }

                        CardSection {
                            width: parent.width
                            height: Theme.rowHeight
                            revealed: islandWindow.expanded && !islandWindow.panelOpen
                            index: 2

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.notificationState.unread > 0
                                    ? root.notificationState.unread + " unread notifications" : "All caught up"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.notificationState.doNotDisturb ? "Do not disturb" : "Notifications"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        CardSection {
                            width: parent.width
                            height: pills.implicitHeight
                            revealed: islandWindow.expanded && !islandWindow.panelOpen
                            index: 3

                            Flow {
                                id: pills
                                width: parent.width
                                spacing: Theme.spaceSm

                                Repeater {
                                    model: ["rashell.system", "rashell.updates", "rashell.tokens", "rashell.keyboard",
                                        "rashell.monitor-input", "rashell.tray", "rashell.bluetooth",
                                        "rashell.audio", "rashell.notifications", "rashell.screenshot", "rashell.control"]

                                    IslandModule {
                                        required property string modelData
                                        moduleId: modelData
                                        outputName: islandWindow.modelData.name
                                    }
                                }
                            }
                        }
                    }

                    Loader {
                        id: panelLoader
                        width: item ? item.implicitWidth : 0
                        height: item ? item.implicitHeight : 0
                        opacity: islandWindow.panelOpen ? 1 : 0
                        enabled: islandWindow.panelOpen

                        Behavior on opacity { NumberAnimation { duration: Theme.motionSurface } }
                    }
                }
            }
        }
    }
}
