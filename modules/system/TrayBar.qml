pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import qs.core

Item {
    id: root
    required property var configStore
    required property var coordinator
    required property string outputName

    readonly property var items: SystemTray.items ? Array.from(SystemTray.items.values) : []
    readonly property var pinnedIds: configStore.trayPinnedIds
    readonly property var pinnedItems: {
        if (pinnedIds === null) return items.slice(0, 3)
        const result = []
        for (let index = 0; index < pinnedIds.length; index++) {
            for (let itemIndex = 0; itemIndex < items.length; itemIndex++) {
                if (pinId(items[itemIndex]) === pinnedIds[index]) result.push(items[itemIndex])
            }
        }
        return result
    }
    readonly property int overflowCount: items.length - pinnedItems.length
    readonly property bool overflowOpened: coordinator.opened
        && coordinator.activePanelId === "tray" && coordinator.anchorItem === overflowButton
    property int menuRequest: 0

    implicitWidth: trayRow.implicitWidth
    implicitHeight: Theme.controlHeight
    visible: items.length > 0

    property var tooltipAnchor: null
    property string tooltipText: ""

    function pinId(item) {
        return item ? String(item.id || "").trim() : ""
    }

    function isPinned(item) {
        return pinnedItems.indexOf(item) !== -1
    }

    function togglePin(item) {
        const id = pinId(item)
        if (id === "" || items.indexOf(item) === -1) return
        const next = pinnedIds === null
            ? pinnedItems.map(entry => pinId(entry)).filter((pin, index, pins) => pin !== "" && pins.indexOf(pin) === index)
            : Array.from(pinnedIds)
        const index = next.indexOf(id)
        if (index === -1) next.push(id)
        else next.splice(index, 1)
        configStore.setTrayPinnedIds(next)
    }

    function closeMenu() {
        ++menuRequest
        if (!trayMenu) return
        trayMenu.close()
        trayMenu.trayItem = null
        trayMenu.anchorItem = null
    }

    function triggerItem(item, button, anchorItem) {
        if (!item || items.indexOf(item) === -1) return
        trayTooltip.visible = false
        tooltipAnchor = null
        const target = anchorItem || overflowButton
        coordinator.close("tray-action")
        closeMenu()
        if (button === Qt.MiddleButton) {
            item.secondaryActivate()
        } else if (button === Qt.RightButton || item.onlyMenu) {
            const token = ++menuRequest
            Qt.callLater(function() {
                if (token !== root.menuRequest || root.coordinator.opened || root.items.indexOf(item) === -1) return
                trayMenu.open(item, target)
            })
        } else {
            item.activate()
        }
    }

    function showTooltip(item, anchorItem) {
        if (coordinator.opened || !item) return
        const title = String(item.tooltipTitle || item.title || item.id || "")
        if (title === "") return
        const characters = Array.from(title)
        root.tooltipText = characters.length > 20
            ? characters.slice(0, 19).join("") + "…"
            : title
        root.tooltipAnchor = anchorItem
        trayTooltip.visible = true
    }

    function hideTooltip(anchorItem) {
        if (root.tooltipAnchor !== anchorItem) return
        if (trayTooltip) trayTooltip.visible = false
        root.tooltipAnchor = null
    }

    onItemsChanged: {
        trayTooltip.visible = false
        tooltipAnchor = null
        if (trayMenu && trayMenu.trayItem && items.indexOf(trayMenu.trayItem) === -1) closeMenu()
        if (items.length === 0 && overflowOpened) coordinator.close("tray-empty")
    }

    Connections {
        target: root.coordinator
        function onOpenedChanged() {
            if (!root.coordinator.opened) return
            root.closeMenu()
            trayTooltip.visible = false
            root.tooltipAnchor = null
        }
    }

    TrayMenu {
        id: trayMenu
    }

    TextMetrics {
        id: tooltipMetrics
        text: root.tooltipText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }

    PopupWindow {
        id: trayTooltip

        visible: false
        color: "transparent"
        implicitWidth: Math.ceil(tooltipMetrics.advanceWidth) + Theme.spaceMd * 2
        implicitHeight: Theme.controlHeight

        anchor {
            id: tooltipPopupAnchor
            window: root.tooltipAnchor ? root.tooltipAnchor.QsWindow.window : null
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                if (!root.tooltipAnchor) return
                const window = root.tooltipAnchor.QsWindow.window
                if (!window) return
                const point = window.contentItem.mapFromItem(
                    root.tooltipAnchor,
                    (root.tooltipAnchor.width - trayTooltip.implicitWidth) / 2,
                    root.tooltipAnchor.height + Theme.panelGap
                )
                tooltipPopupAnchor.rect.x = Math.round(point.x)
                tooltipPopupAnchor.rect.y = Math.round(point.y)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceRaised
            border.color: Theme.borderInteractive
            border.width: Theme.borderWidth
            radius: Theme.radius

            Text {
                id: tooltipLabel
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceMd
                anchors.rightMargin: Theme.spaceMd
                text: root.tooltipText
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceXs

        Repeater {
            model: root.pinnedItems

            TrayButton {
                id: trayButton
                required property var modelData
                trayItem: modelData
                width: 32
                height: Theme.controlHeight
                onTriggered: button => root.triggerItem(modelData, button, trayButton)
                onHovered: entered => {
                    if (entered) root.showTooltip(modelData, trayButton)
                    else root.hideTooltip(trayButton)
                }
                Component.onDestruction: {
                    root.hideTooltip(trayButton)
                    if (trayMenu && trayMenu.anchorItem === trayButton) root.closeMenu()
                }
            }
        }

        Button {
            id: overflowButton
            width: 32
            height: Theme.controlHeight
            hoverEnabled: true
            Accessible.name: "Tray applications, " + root.overflowCount + " hidden. Manage pinned apps"
            ToolTip.visible: hovered && !root.overflowOpened
            ToolTip.text: root.overflowCount > 0 ? root.overflowCount + " more apps" : "Manage tray apps"

            contentItem: Text {
                text: root.overflowOpened ? "󰅃" : "󰅀"
                color: root.overflowOpened ? Theme.accent : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: Theme.radius
                color: root.overflowOpened || overflowButton.hovered || overflowButton.down
                    ? Theme.surfaceRaised : "transparent"
                border.color: overflowButton.activeFocus ? Theme.focus : "transparent"
                border.width: Theme.borderWidth
            }

            onClicked: {
                root.closeMenu()
                root.coordinator.toggle(
                    "tray", overflowButton, "right",
                    Quickshell.shellDir + "/modules/system/TrayOverflowPanel.qml",
                    { trayBar: root, coordinator: root.coordinator }
                )
            }
        }
    }

    Component.onCompleted: coordinator.registerAnchor("tray", outputName, overflowButton, "right")
    Component.onDestruction: {
        closeMenu()
        coordinator.unregisterAnchor("tray", outputName, overflowButton)
    }
}
