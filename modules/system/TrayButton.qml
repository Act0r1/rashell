pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property var trayItem
    property bool showLabel: false
    readonly property string label: trayItem
        ? String(trayItem.tooltipTitle || trayItem.title || trayItem.id || "Application") : "Application"

    implicitWidth: showLabel ? 220 : 32
    implicitHeight: Theme.controlHeight
    activeFocusOnTab: true
    Accessible.name: label
    Accessible.role: Accessible.Button
    Accessible.onPressAction: root.triggered(Qt.LeftButton)

    signal triggered(int button)
    signal hovered(bool entered)

    function iconSource() {
        const icon = trayItem ? String(trayItem.icon || "") : ""
        if (!icon.includes("?path=")) return icon
        const chunks = icon.split("?path=")
        const fileName = chunks[0].substring(chunks[0].lastIndexOf("/") + 1)
        return "file://" + chunks[1] + "/" + fileName
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.triggered(Qt.LeftButton)
            event.accepted = true
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
            root.triggered(Qt.RightButton)
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: mouse.containsMouse ? Theme.surfaceRaised : "transparent"
        border.color: root.activeFocus ? Theme.focus : "transparent"
        border.width: Theme.borderWidth
    }

    Item {
        width: 32
        height: parent.height
        x: root.showLabel ? 0 : (parent.width - width) / 2

        IconImage {
            id: icon
            anchors.centerIn: parent
            width: 18
            height: 18
            source: root.iconSource()
            asynchronous: true
            backer.fillMode: Image.PreserveAspectFit
            opacity: status === Image.Ready ? 1 : 0
        }

        Text {
            anchors.centerIn: parent
            visible: icon.status === Image.Error || icon.status === Image.Null
            text: "·"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 38
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showLabel
        text: root.label
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onEntered: root.hovered(true)
        onExited: root.hovered(false)
        onClicked: event => root.triggered(event.button)
    }
}
