pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Rectangle {
    id: root

    required property var trayBar
    required property var coordinator
    property string hoveredLabel: ""

    implicitWidth: Math.max(title.implicitWidth, appGrid.implicitWidth, trayBar.overflowCount === 0 ? 156 : 0)
        + Theme.panelPadding * 2
    implicitHeight: content.implicitHeight + Theme.panelPadding * 2
    color: Theme.surface
    border.color: hiddenDrop.containsDrag ? Theme.accent : Theme.borderInteractive
    border.width: Theme.borderWidth
    radius: Theme.radius
    focus: true

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.trayBar.draggedItem === null
        onActivated: root.coordinator.close("escape")
    }

    DropArea {
        id: hiddenDrop
        anchors.fill: parent
        keys: [root.trayBar.dragMimeType]
        onEntered: event => { event.accepted = root.trayBar.acceptsDrag(event) }
        onDropped: event => root.trayBar.acceptDrop(event, false)
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.panelPadding
        spacing: Theme.spaceSm

        Text {
            id: title
            text: "Hidden apps"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
        }

        Grid {
            id: appGrid
            columns: Math.min(5, Math.max(1, root.trayBar.overflowCount))
            spacing: Theme.spaceSm

            Repeater {
                model: root.trayBar.overflowItems

                TrayButton {
                    id: appButton
                    required property var modelData
                    trayItem: modelData
                    width: 36
                    height: 36
                    draggable: root.trayBar.pinId(modelData) !== ""
                    dragMimeType: root.trayBar.dragMimeType
                    onTriggered: button => root.trayBar.triggerItem(modelData, button, null)
                    onDragStarted: root.trayBar.beginDrag(modelData)
                    onDragFinished: action => root.trayBar.finishDrag(action)
                    onHovered: entered => { root.hoveredLabel = entered ? label : "" }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.trayBar.overflowCount === 0
            text: "Drop apps here to hide them"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            topPadding: Theme.spaceSm
            bottomPadding: Theme.spaceSm
        }

        Text {
            width: parent.width
            visible: root.trayBar.overflowCount > 0
            text: root.hoveredLabel || "Drag to bar to pin"
            color: root.hoveredLabel ? Theme.text : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }
}
