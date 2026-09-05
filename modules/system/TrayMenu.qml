pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core

Scope {
    id: root

    property var trayItem: null
    property var anchorItem: null
    readonly property bool inSubmenu: entryStack.count > 0
    readonly property color accentTintedSurface: Qt.tint(
        Theme.surface,
        Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.07)
    )
    readonly property color accentTintedHover: Qt.tint(
        Theme.surfaceRaised,
        Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
    )
    readonly property color accentTintedBorder: Qt.tint(
        Theme.borderInteractive,
        Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
    )

    function open(item, anchorItem) {
        if (!item || !item.hasMenu) return
        root.trayItem = item
        root.anchorItem = anchorItem
        entryStack.clear()
        popup.visible = true
    }

    function close() {
        popup.visible = false
        entryStack.clear()
    }

    function topEntry() {
        return entryStack.count > 0 ? entryStack.get(entryStack.count - 1).handle : null
    }

    function showSubmenu(entry) {
        if (!entry || !entry.hasChildren) return
        entryStack.append({ handle: entry })
        if (typeof entry.updateLayout === "function") entry.updateLayout()
        submenuHydrator.menu = entry.menu || entry
        submenuHydrator.open()
        Qt.callLater(() => submenuHydrator.close())
    }

    function trigger(entry) {
        if (!entry || entry.isSeparator || entry.enabled === false) return
        if (entry.hasChildren) {
            showSubmenu(entry)
            return
        }
        if (typeof entry.activate === "function") entry.activate()
        else if (typeof entry.triggered === "function") entry.triggered()
        closeTimer.restart()
    }

    ListModel {
        id: entryStack
    }

    Timer {
        id: closeTimer
        interval: 80
        onTriggered: root.close()
    }

    QsMenuOpener {
        id: rootOpener
        menu: root.trayItem ? root.trayItem.menu : null
    }

    QsMenuOpener {
        id: submenuOpener
        menu: {
            const entry = root.topEntry()
            return entry ? (entry.menu || entry) : null
        }
    }

    PopupWindow {
        id: popup

        visible: false
        color: "transparent"
        grabFocus: true
        implicitWidth: 280
        implicitHeight: Math.min(480, Math.max(Theme.rowHeight, menuColumn.implicitHeight + Theme.spaceMd * 2))

        anchor {
            id: popupAnchor
            window: root.anchorItem ? root.anchorItem.QsWindow.window : null
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                if (!root.anchorItem) return
                const window = root.anchorItem.QsWindow.window
                if (!window) return
                const point = window.contentItem.mapFromItem(
                    root.anchorItem,
                    root.anchorItem.width - popup.implicitWidth,
                    root.anchorItem.height + Theme.panelGap
                )
                popupAnchor.rect.x = Math.round(point.x)
                popupAnchor.rect.y = Math.round(point.y)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: root.accentTintedSurface
            border.color: root.accentTintedBorder
            border.width: Theme.borderWidth
            radius: Theme.radius
            focus: true

            Keys.onEscapePressed: event => {
                if (entryStack.count > 0) entryStack.remove(entryStack.count - 1)
                else root.close()
                event.accepted = true
            }

            QsMenuAnchor {
                id: submenuHydrator
                anchor.window: popup
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                contentWidth: width
                contentHeight: menuColumn.implicitHeight
                clip: true
                interactive: contentHeight > height

                Column {
                    id: menuColumn
                    width: parent.width
                    spacing: Theme.spaceXs

                    Rectangle {
                        width: parent.width
                        height: Theme.controlHeight
                        visible: root.inSubmenu
                        color: backMouse.containsMouse ? root.accentTintedHover : "transparent"
                        radius: Theme.radius

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spaceMd
                            anchors.verticalCenter: parent.verticalCenter
                            text: "‹  BACK"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entryStack.remove(entryStack.count - 1)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: Theme.borderWidth
                        visible: root.inSubmenu
                        color: root.accentTintedBorder
                    }

                    Repeater {
                        model: root.inSubmenu ? submenuOpener.children : rootOpener.children

                        Rectangle {
                            id: menuRow
                            required property var modelData
                            readonly property var menuEntry: modelData
                            width: menuColumn.width
                            height: menuEntry && menuEntry.isSeparator ? Theme.borderWidth : Theme.controlHeight
                            radius: menuEntry && menuEntry.isSeparator ? 0 : Theme.radius
                            color: {
                                if (menuEntry && menuEntry.isSeparator) return root.accentTintedBorder
                                return rowMouse.containsMouse && menuEntry.enabled !== false
                                    ? root.accentTintedHover : "transparent"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spaceMd
                                anchors.rightMargin: Theme.spaceMd
                                spacing: Theme.spaceMd
                                visible: menuEntry && !menuEntry.isSeparator
                                opacity: menuEntry && menuEntry.enabled === false ? 0.55 : 1

                                Item {
                                    width: 16
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14
                                        visible: menuRow.menuEntry && menuRow.menuEntry.buttonType !== QsMenuButtonType.None
                                        radius: menuRow.menuEntry && menuRow.menuEntry.buttonType === QsMenuButtonType.RadioButton ? 7 : 2
                                        color: "transparent"
                                        border.color: root.accentTintedBorder
                                        border.width: Theme.borderWidth

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 8
                                            height: 8
                                            radius: parent.radius > 2 ? 4 : 1
                                            visible: menuRow.menuEntry && menuRow.menuEntry.checkState === Qt.Checked
                                            color: Theme.accent
                                        }
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        visible: menuRow.menuEntry
                                            && menuRow.menuEntry.buttonType === QsMenuButtonType.None
                                            && String(menuRow.menuEntry.icon || "") !== ""
                                        source: menuRow.menuEntry ? menuRow.menuEntry.icon : ""
                                        asynchronous: true
                                        backer.fillMode: Image.PreserveAspectFit
                                    }
                                }

                                Text {
                                    width: parent.width - 48
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: menuRow.menuEntry ? menuRow.menuEntry.text : ""
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: menuRow.menuEntry && menuRow.menuEntry.hasChildren ? "›" : ""
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontTitle
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                enabled: menuRow.menuEntry
                                    && !menuRow.menuEntry.isSeparator
                                    && menuRow.menuEntry.enabled !== false
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.trigger(menuRow.menuEntry)
                            }
                        }
                    }
                }
            }
        }
    }
}
