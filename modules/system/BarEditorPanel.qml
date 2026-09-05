pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
        "rashell.updates": "Updates"
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

        width: 208
        height: 36
        color: Theme.surfaceRaised
        border.color: Theme.accentMuted
        border.width: Theme.borderWidth
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
                leftMargin: Theme.spaceMd
                right: controls.left
                rightMargin: Theme.spaceSm
                verticalCenter: parent.verticalCenter
            }
            text: root.moduleNames[card.moduleId] || card.moduleId
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
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
                width: 26
                height: 28
                text: "‹"
                enabled: card.moduleIndex > 0
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " earlier"
                onClicked: root.moveWithin(card.moduleId, card.zoneName, -1)
            }
            ActionButton {
                width: 26
                height: 28
                text: "›"
                enabled: card.moduleIndex < card.moduleCount - 1
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " later"
                onClicked: root.moveWithin(card.moduleId, card.zoneName, 1)
            }
            ActionButton {
                width: 26
                height: 28
                text: "↪"
                accessibleName: "Move " + root.moduleNames[card.moduleId] + " to the next zone"
                onClicked: root.moveTo(card.moduleId, root.nextZone(card.zoneName))
            }
            ActionButton {
                width: 26
                height: 28
                text: "×"
                danger: true
                accessibleName: "Hide " + root.moduleNames[card.moduleId]
                onClicked: root.moveTo(card.moduleId, "hidden")
            }
        }
    }

    component HiddenWidgetCard: Rectangle {
        id: hiddenCard

        required property string moduleId

        width: 208
        height: 36
        color: Theme.surfaceRaised
        border.color: Theme.borderInteractive
        border.width: Theme.borderWidth
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
                leftMargin: Theme.spaceMd
                right: controls.left
                rightMargin: Theme.spaceSm
                verticalCenter: parent.verticalCenter
            }
            text: root.moduleNames[hiddenCard.moduleId] || hiddenCard.moduleId
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
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
                    width: 28
                    height: 28
                    text: modelData.charAt(0).toUpperCase()
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
        implicitHeight: Math.max(108, widgetsFlow.implicitHeight + 48)
        color: Theme.surface
        border.color: Theme.border
        border.width: Theme.borderWidth
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
            text: zoneSection.title.toUpperCase()
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            font.letterSpacing: 1
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: Theme.spaceLg
                top: parent.top
                topMargin: Theme.spaceMd
            }
            text: zoneSection.modules.length + " WIDGET" + (zoneSection.modules.length === 1 ? "" : "S")
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
                topMargin: 36
            }
            spacing: Theme.spaceMd

            Text {
                visible: zoneSection.modules.length === 0
                text: "Empty zone"
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
            id: card
            width: Math.min(800, window.width - 64)
            height: Math.min(650, window.height - 64)
            anchors.centerIn: parent
            color: Theme.background
            border.color: Theme.borderInteractive
            border.width: Theme.borderWidth
            radius: Theme.radius

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            Column {
                anchors {
                    fill: parent
                    margins: Theme.spaceXl
                }
                spacing: Theme.spaceLg

                Item {
                    width: parent.width
                    height: Theme.compactControlSize

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        text: "[ BAR SETTINGS ]"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    ActionButton {
                        anchors.right: parent.right
                        width: Theme.compactControlSize
                        text: "X"
                        accessibleName: "Close bar settings"
                        onClicked: root.close()
                    }
                }

                Rectangle { width: parent.width; height: Theme.borderWidth; color: Theme.border }

                Row {
                    width: parent.width
                    spacing: Theme.spaceSm

                    Repeater {
                        model: ["APPEARANCE", "WIDGETS", "BEHAVIOR", "MONITORS"]
                        ActionButton {
                            required property string modelData
                            width: (parent.width - parent.spacing * 3) / 4
                            text: modelData
                            selected: modelData === "WIDGETS"
                            enabled: modelData === "WIDGETS"
                            accessibleName: modelData.toLowerCase() + " settings"
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "Drag widgets to reorder or move them between zones. Drop into Hidden Widgets to hide. Press Esc to close."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }

                ScrollView {
                    width: parent.width
                    height: parent.height - 172
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Column {
                        width: parent.width
                        spacing: Theme.spaceMd

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
                            implicitHeight: Math.max(108, hiddenFlow.implicitHeight + 48)
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: Theme.borderWidth
                            radius: Theme.radius

                            DropArea {
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
                                text: "HIDDEN WIDGETS"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                                font.letterSpacing: 1
                            }

                            Flow {
                                id: hiddenFlow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    leftMargin: Theme.spaceLg
                                    rightMargin: Theme.spaceLg
                                    topMargin: 36
                                }
                                spacing: Theme.spaceMd

                                Text {
                                    visible: root.hiddenModules.length === 0
                                    text: "All widgets are visible"
                                    color: Theme.textDisabled
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    topPadding: Theme.spaceMd
                                }

                                Repeater {
                                    model: root.hiddenModules
                                    HiddenWidgetCard {
                                        required property string modelData
                                        moduleId: modelData
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.hiddenModules.indexOf("rashell.control") !== -1
                            text: "Control center is hidden. Restore it here or edit config.json to get this button back."
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd

                    ActionButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        text: "CANCEL"
                        accessibleName: "Cancel bar changes"
                        onClicked: root.close()
                    }
                    ActionButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        text: "REVERT"
                        accessibleName: "Revert unapplied bar changes"
                        onClicked: root.loadDraft()
                    }
                    ActionButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        text: "APPLY"
                        selected: true
                        accessibleName: "Apply bar layout"
                        onClicked: root.applyDraft()
                    }
                }
            }
        }
    }
}
