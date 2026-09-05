pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.core

Rectangle {
    id: root

    required property var trayBar
    required property var coordinator

    implicitWidth: 320
    implicitHeight: Math.min(440, header.implicitHeight + appColumn.implicitHeight + Theme.panelPadding * 3)
    color: Theme.surface
    border.color: Theme.borderInteractive
    border.width: Theme.borderWidth
    radius: Theme.radius
    focus: true

    Keys.onEscapePressed: event => {
        root.coordinator.close("escape")
        event.accepted = true
    }

    Column {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.panelPadding
        spacing: Theme.spaceSm

        Text {
            text: "Tray applications"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            font.bold: true
        }

        Text {
            text: "Pin apps to keep them on the bar."
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }

    Flickable {
        id: appList
        anchors.top: header.bottom
        anchors.topMargin: Theme.panelPadding
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.panelPadding
        anchors.rightMargin: Theme.panelPadding
        anchors.bottomMargin: Theme.panelPadding
        contentWidth: width
        contentHeight: appColumn.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        function ensureVisible(item) {
            if (item.y < contentY) contentY = item.y
            else if (item.y + item.height > contentY + height) contentY = item.y + item.height - height
        }

        Column {
            id: appColumn
            width: parent.width - (appList.contentHeight > appList.height ? 8 : 0)
            spacing: Theme.spaceSm

            Repeater {
                model: root.trayBar.items

                Row {
                    id: appRow
                    required property var modelData
                    width: appColumn.width
                    spacing: Theme.spaceSm

                    TrayButton {
                        trayItem: appRow.modelData
                        width: appRow.width - pinButton.width - appRow.spacing
                        height: 36
                        showLabel: true
                        onActiveFocusChanged: if (activeFocus) appList.ensureVisible(appRow)
                        onTriggered: button => root.trayBar.triggerItem(appRow.modelData, button, null)
                    }

                    Button {
                        id: pinButton
                        readonly property bool pinned: root.trayBar.isPinned(appRow.modelData)
                        width: 36
                        height: 36
                        enabled: root.trayBar.pinId(appRow.modelData) !== ""
                        hoverEnabled: true
                        onActiveFocusChanged: if (activeFocus) appList.ensureVisible(appRow)
                        Accessible.name: (pinned ? "Unpin " : "Pin ")
                            + (appRow.modelData ? String(appRow.modelData.title || appRow.modelData.id || "application") : "application")
                        ToolTip.visible: hovered
                        ToolTip.text: pinned ? "Unpin from bar" : "Pin to bar"

                        contentItem: Text {
                            text: pinButton.pinned ? "󰐃" : "󰤱"
                            color: !pinButton.enabled ? Theme.textDisabled
                                : pinButton.pinned ? Theme.accent : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: Theme.radius
                            color: pinButton.hovered || pinButton.down ? Theme.surfaceRaised : "transparent"
                            border.color: pinButton.activeFocus ? Theme.focus : "transparent"
                            border.width: Theme.borderWidth
                        }

                        onClicked: root.trayBar.togglePin(appRow.modelData)
                    }
                }
            }
        }
    }
}
