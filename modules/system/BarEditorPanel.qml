pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root

    required property var configStore

    property bool opened: false
    property var targetScreen: null
    property var draftLeft: []
    property var draftCenter: []
    property var draftRight: []
    property int draftRevision: 0

    readonly property var hiddenModules: {
        root.draftRevision
        return root.configStore.barModuleIds.filter(function(moduleId) {
            return root.draftLeft.indexOf(moduleId) === -1
                && root.draftCenter.indexOf(moduleId) === -1
                && root.draftRight.indexOf(moduleId) === -1
        })
    }

    readonly property var moduleNames: ({
        "rashell.workspaces": "Workspaces",
        "rashell.clock": "Clock",
        "rashell.weather": "Weather",
        "rashell.audio": "Audio",
        "rashell.media": "Media",
        "rashell.screenshot": "Screenshot",
        "rashell.keyboard": "Keyboard",
        "rashell.tray": "System tray",
        "rashell.bluetooth": "Bluetooth",
        "rashell.system": "System status",
        "rashell.control": "Control center",
        "rashell.tokens": "Token usage",
        "rashell.notifications": "Notifications",
        "rashell.updates": "Updates",
        "rashell.monitor-input": "Monitor input"
    })

    function open(screen) {
        loadDraft()
        targetScreen = screen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        opened = targetScreen !== null
    }

    function close() {
        opened = false
    }

    function loadDraft() {
        draftLeft = Array.from(configStore.leftModules)
        draftCenter = Array.from(configStore.centerModules)
        draftRight = Array.from(configStore.rightModules)
        draftRevision++
    }

    function modulesFor(zone) {
        draftRevision
        if (zone === "left") return draftLeft
        if (zone === "center") return draftCenter
        if (zone === "right") return draftRight
        return hiddenModules
    }

    function updateDraft(left, center, right) {
        draftLeft = left
        draftCenter = center
        draftRight = right
        draftRevision++
    }

    function moveTo(moduleId, targetZone) {
        const left = draftLeft.filter(function(item) { return item !== moduleId })
        const center = draftCenter.filter(function(item) { return item !== moduleId })
        const right = draftRight.filter(function(item) { return item !== moduleId })

        if (targetZone === "left") left.push(moduleId)
        else if (targetZone === "center") center.push(moduleId)
        else if (targetZone === "right") right.push(moduleId)

        updateDraft(left, center, right)
    }

    function moveWithin(moduleId, zoneName, delta) {
        const left = Array.from(draftLeft)
        const center = Array.from(draftCenter)
        const right = Array.from(draftRight)
        const zone = zoneName === "left" ? left : zoneName === "center" ? center : right
        const currentIndex = zone.indexOf(moduleId)
        const nextIndex = currentIndex + delta
        if (currentIndex < 0 || nextIndex < 0 || nextIndex >= zone.length) return

        const displaced = zone[nextIndex]
        zone[nextIndex] = moduleId
        zone[currentIndex] = displaced
        updateDraft(left, center, right)
    }

    function moveAt(moduleId, targetZone, targetIndex) {
        const left = draftLeft.filter(function(item) { return item !== moduleId })
        const center = draftCenter.filter(function(item) { return item !== moduleId })
        const right = draftRight.filter(function(item) { return item !== moduleId })
        const zone = targetZone === "left" ? left : targetZone === "center" ? center : right
        const index = Math.max(0, Math.min(targetIndex, zone.length))
        zone.splice(index, 0, moduleId)
        updateDraft(left, center, right)
    }

    function nextZone(zoneName) {
        if (zoneName === "left") return "center"
        if (zoneName === "center") return "right"
        return "left"
    }

    function applyDraft() {
        if (configStore.setBar(draftLeft, draftCenter, draftRight)) close()
    }

    component CardDragArea: MouseArea {
        required property Item dragItem

        property real originX: 0
        property real originY: 0

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: dragItem
        drag.axis: Drag.XAndYAxis
        drag.smoothed: false

        onPressed: {
            originX = dragItem.x
            originY = dragItem.y
        }
        onReleased: {
            dragItem.Drag.drop()
            dragItem.x = originX
            dragItem.y = originY
        }
        onCanceled: {
            dragItem.x = originX
            dragItem.y = originY
        }
    }

    component WidgetCard: Rectangle {
        id: card

        required property string moduleId
        required property string zoneName
        required property int moduleIndex
        required property int moduleCount

        width: 340
        height: Theme.rowHeight + Theme.spaceSm
        color: dragArea.containsMouse || Drag.active ? Theme.hoverSurface : Theme.surfaceRaised
        border.color: Theme.accent
        border.width: Drag.active ? Theme.focusWidth : 0
        radius: Theme.radius
        opacity: Drag.active ? 0.78 : 1
        z: Drag.active ? 100 : 0

        Drag.active: dragArea.drag.active
        Drag.source: card
        Drag.keys: ["bar-widget"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.supportedActions: Qt.MoveAction

        CardDragArea {
            id: dragArea
            dragItem: card
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: Theme.spaceLg
                right: controls.left
                rightMargin: Theme.spaceSm
                verticalCenter: parent.verticalCenter
            }
            text: root.moduleNames[card.moduleId] || card.moduleId
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
        }

        Row {
            id: controls
            anchors {
                right: parent.right
                rightMargin: Theme.spaceXs
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.spaceXs

            ActionButton {
                width: Theme.controlHeight
                height: Theme.controlHeight
                leftPadding: 0
                rightPadding: 0
                flat: true
                text: "‹"
                enabled: card.moduleIndex > 0
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " earlier"
                onClicked: root.moveWithin(card.moduleId, card.zoneName, -1)
            }
            ActionButton {
                width: Theme.controlHeight
                height: Theme.controlHeight
                leftPadding: 0
                rightPadding: 0
                flat: true
                text: "›"
                enabled: card.moduleIndex < card.moduleCount - 1
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " later"
                onClicked: root.moveWithin(card.moduleId, card.zoneName, 1)
            }
            ActionButton {
                width: 80
                height: Theme.controlHeight
                leftPadding: 0
                rightPadding: 0
                flat: true
                text: "→ " + root.nextZone(card.zoneName).charAt(0).toUpperCase() + root.nextZone(card.zoneName).slice(1)
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " to the " + root.nextZone(card.zoneName) + " zone"
                onClicked: root.moveTo(card.moduleId, root.nextZone(card.zoneName))
            }
            ActionButton {
                width: 44
                height: Theme.controlHeight
                leftPadding: 0
                rightPadding: 0
                flat: true
                text: "Hide"
                accessibleName: "Hide " + root.moduleNames[card.moduleId]
                onClicked: root.moveTo(card.moduleId, "hidden")
            }
        }
    }

    component HiddenWidgetCard: Rectangle {
        id: hiddenCard

        required property string moduleId

        width: 340
        height: Theme.rowHeight + Theme.spaceSm
        color: hiddenDragArea.containsMouse || Drag.active ? Theme.hoverSurface : Theme.surfaceRaised
        border.color: Theme.accent
        border.width: Drag.active ? Theme.focusWidth : 0
        radius: Theme.radius
        opacity: Drag.active ? 0.78 : 1
        z: Drag.active ? 100 : 0

        Drag.active: hiddenDragArea.drag.active
        Drag.source: hiddenCard
        Drag.keys: ["bar-widget"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.supportedActions: Qt.MoveAction

        CardDragArea {
            id: hiddenDragArea
            dragItem: hiddenCard
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: Theme.spaceLg
                right: controls.left
                rightMargin: Theme.spaceSm
                verticalCenter: parent.verticalCenter
            }
            text: root.moduleNames[hiddenCard.moduleId] || hiddenCard.moduleId
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
        }

        Row {
            id: controls
            anchors {
                right: parent.right
                rightMargin: Theme.spaceXs
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.spaceXs

            Repeater {
                model: ["left", "center", "right"]
                ActionButton {
                    required property string modelData
                    width: modelData === "center" ? 60 : 48
                    height: Theme.controlHeight
                    leftPadding: Theme.spaceSm
                    rightPadding: Theme.spaceSm
                    flat: true
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    accessibleName: "Show " + root.moduleNames[hiddenCard.moduleId] + " on the " + modelData
                    onClicked: root.moveTo(hiddenCard.moduleId, modelData)
                }
            }
        }
    }

    component ZoneSection: Rectangle {
        id: zoneSection

        required property string zoneName
        required property string title
        required property var modules

        width: parent.width
        implicitHeight: widgetsFlow.y + Math.max(Theme.controlHeight, widgetsFlow.implicitHeight) + Theme.spaceMd
        color: zoneDrop.containsDrag ? Theme.selectedSurface : "transparent"
        border.color: Theme.accent
        border.width: zoneDrop.containsDrag ? Theme.borderWidth : 0
        radius: Theme.radius

        function dropIndex(dropX, dropY, sourceId) {
            let targetIndex = 0
            for (let i = 0; i < widgetRepeater.count; i++) {
                const item = widgetRepeater.itemAt(i)
                if (!item || item.moduleId === sourceId) continue

                const itemTop = widgetsFlow.y + item.y
                const itemBottom = itemTop + item.height
                const itemCenterX = widgetsFlow.x + item.x + item.width / 2
                if (dropY < itemTop || (dropY <= itemBottom && dropX < itemCenterX))
                    return targetIndex
                targetIndex++
            }
            return targetIndex
        }

        DropArea {
            id: zoneDrop
            anchors.fill: parent
            keys: ["bar-widget"]
            onDropped: drop => {
                const index = zoneSection.dropIndex(drop.x, drop.y, drop.source.moduleId)
                root.moveAt(drop.source.moduleId, zoneSection.zoneName, index)
                drop.acceptProposedAction()
            }
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: Theme.spaceLg
                top: parent.top
                topMargin: Theme.spaceMd
            }
            text: zoneSection.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.DemiBold
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: Theme.spaceLg
                top: parent.top
                topMargin: Theme.spaceMd
            }
            text: zoneSection.modules.length + (zoneSection.modules.length === 1 ? " widget" : " widgets")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Flow {
            id: widgetsFlow
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Theme.spaceLg
                rightMargin: Theme.spaceLg
                topMargin: Theme.controlHeight + Theme.spaceSm
            }
            spacing: Theme.spaceMd

            Text {
                visible: zoneSection.modules.length === 0
                text: "Drop widgets here"
                color: Theme.textDisabled
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                topPadding: Theme.spaceMd
            }

            Repeater {
                id: widgetRepeater
                model: zoneSection.modules
                WidgetCard {
                    required property string modelData
                    required property int index
                    width: widgetsFlow.width >= 620 ? (widgetsFlow.width - widgetsFlow.spacing) / 2 : widgetsFlow.width
                    moduleId: modelData
                    moduleIndex: index
                    moduleCount: zoneSection.modules.length
                    zoneName: zoneSection.zoneName
                }
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.ApplicationShortcut
        enabled: root.opened
        onActivated: root.close()
    }

    PanelWindow {
        id: window

        screen: root.targetScreen
        visible: root.opened && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "rashell-bar-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.58)

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: editorCard
            width: Math.min(840, window.width - Theme.spaceXl * 4)
            height: Math.min(720, window.height - Theme.spaceXl * 4)
            anchors.centerIn: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radius

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: Theme.spaceXl
                }
                spacing: Theme.spaceLg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceLg

                    Text {
                        Layout.fillWidth: true
                        text: "Customize bar"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.DemiBold
                    }

                    CloseButton {
                        accessibleName: "Close bar settings"
                        onClicked: root.close()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Drag widgets between zones or use their controls. Apply to save your layout."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceMd

                    Text {
                        Layout.fillWidth: true
                        text: "Minimal mode keeps only the clock and weather on a transparent bar."
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.WordWrap
                    }

                    ActionButton {
                        text: root.configStore.barMinimal ? "Minimal mode: On" : "Minimal mode: Off"
                        selected: root.configStore.barMinimal
                        accessibleName: "Toggle minimal bar mode"
                        onClicked: root.configStore.setBarMinimal(!root.configStore.barMinimal)
                    }
                }

                ScrollView {
                    id: editorScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    clip: true
                    rightPadding: Theme.spaceLg
                    contentWidth: availableWidth
                    contentHeight: sections.implicitHeight
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical: ScrollBar {
                        parent: editorScroll
                        x: editorScroll.width - width
                        y: editorScroll.topPadding
                        width: Theme.spaceMd
                        height: editorScroll.availableHeight
                        orientation: Qt.Vertical
                        policy: ScrollBar.AsNeeded
                        active: true
                        contentItem: Rectangle {
                            implicitWidth: Theme.spaceSm
                            implicitHeight: Theme.spaceSm
                            radius: Theme.spaceXs
                            color: Theme.borderInteractive
                        }
                    }

                    Column {
                        id: sections
                        width: editorScroll.availableWidth
                        spacing: Theme.spaceMd
                        bottomPadding: Theme.spaceMd

                        ZoneSection {
                            zoneName: "left"
                            title: "Left"
                            modules: root.modulesFor("left")
                        }
                        ZoneSection {
                            zoneName: "center"
                            title: "Center"
                            modules: root.modulesFor("center")
                        }
                        ZoneSection {
                            zoneName: "right"
                            title: "Right"
                            modules: root.modulesFor("right")
                        }

                        Rectangle {
                            width: parent.width
                            implicitHeight: hiddenFlow.y + Math.max(Theme.controlHeight, hiddenFlow.implicitHeight) + Theme.spaceMd
                            color: hiddenDrop.containsDrag ? Theme.selectedSurface : "transparent"
                            border.color: Theme.accent
                            border.width: hiddenDrop.containsDrag ? Theme.borderWidth : 0
                            radius: Theme.radius

                            DropArea {
                                id: hiddenDrop
                                anchors.fill: parent
                                keys: ["bar-widget"]
                                onDropped: drop => {
                                    root.moveTo(drop.source.moduleId, "hidden")
                                    drop.acceptProposedAction()
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: Theme.spaceLg
                                    top: parent.top
                                    topMargin: Theme.spaceMd
                                }
                                text: "Hidden widgets"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors {
                                    right: parent.right
                                    rightMargin: Theme.spaceLg
                                    top: parent.top
                                    topMargin: Theme.spaceMd
                                }
                                text: root.hiddenModules.length + (root.hiddenModules.length === 1 ? " widget" : " widgets")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }

                            Flow {
                                id: hiddenFlow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    leftMargin: Theme.spaceLg
                                    rightMargin: Theme.spaceLg
                                    topMargin: Theme.controlHeight + Theme.spaceSm
                                }
                                spacing: Theme.spaceMd

                                Text {
                                    visible: root.hiddenModules.length === 0
                                    text: "Drop a widget here to hide it"
                                    color: Theme.textDisabled
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    topPadding: Theme.spaceMd
                                }

                                Repeater {
                                    model: root.hiddenModules
                                    HiddenWidgetCard {
                                        required property string modelData
                                        width: hiddenFlow.width >= 620 ? (hiddenFlow.width - hiddenFlow.spacing) / 2 : hiddenFlow.width
                                        moduleId: modelData
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.hiddenModules.indexOf("rashell.control") !== -1
                            text: "Control center is hidden. Add it to a zone above to show it again."
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.borderWidth
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceMd

                    ActionButton {
                        text: "Cancel"
                        flat: true
                        implicitHeight: Theme.rowHeight
                        accessibleName: "Cancel bar changes"
                        onClicked: root.close()
                    }
                    ActionButton {
                        text: "Revert changes"
                        flat: true
                        implicitHeight: Theme.rowHeight
                        accessibleName: "Revert unapplied bar changes"
                        onClicked: root.loadDraft()
                    }
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        text: "Apply layout"
                        selected: true
                        implicitHeight: Theme.rowHeight
                        accessibleName: "Apply bar layout"
                        onClicked: root.applyDraft()
                    }
                }
            }
        }
    }
}
