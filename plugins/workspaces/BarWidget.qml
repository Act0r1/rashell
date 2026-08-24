pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

Item {
    id: root

    property var manifest: null
    property var pluginRegistry: null
    property var workspaceIds: [1, 2, 3, 4, 5, 6]

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: Theme.controlHeight

    function workspaceById(workspaceId) {
        const values = Hyprland.workspaces.values
        for (let index = 0; index < values.length; index++) {
            if (values[index].id === workspaceId) return values[index]
        }
        return null
    }

    function focusWorkspace(workspaceId) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(workspaceId)])
    }

    Row {
        id: workspaceRow
        spacing: 4

        Repeater {
            model: root.workspaceIds

            Rectangle {
                id: workspaceButton

                required property int modelData
                readonly property var workspace: root.workspaceById(modelData)
                readonly property bool focused: Hyprland.focusedWorkspace !== null
                    && Hyprland.focusedWorkspace.id === modelData
                readonly property bool occupied: workspace !== null
                    && workspace.toplevels.values.length > 0

                width: 32
                height: Theme.controlHeight
                color: focused ? Theme.accent : workspaceHover.hovered ? Theme.surfaceRaised : "transparent"
                border.color: focused ? Theme.accent : Theme.border
                border.width: 1
                radius: Theme.radius

                Text {
                    anchors.centerIn: parent
                    text: workspaceButton.modelData
                    color: workspaceButton.focused ? Theme.background
                        : workspaceButton.occupied ? Theme.text : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.bold: workspaceButton.focused
                }

                HoverHandler {
                    id: workspaceHover
                }

                TapHandler {
                    onTapped: root.focusWorkspace(workspaceButton.modelData)
                }
            }
        }
    }
}
