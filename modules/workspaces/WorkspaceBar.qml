pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root

    required property var state
    required property string outputName
    property int menuWorkspaceId: -1
    property Item menuAnchor: null

    function openMenu(workspaceId, anchorItem) {
        menuWorkspaceId = workspaceId
        menuAnchor = anchorItem
        menu.visible = true
    }

    implicitWidth: state.available ? row.implicitWidth : unavailableLabel.implicitWidth
    implicitHeight: Theme.controlHeight

    Text {
        id: unavailableLabel
        visible: !root.state.available
        anchors.verticalCenter: parent.verticalCenter
        text: "WORKSPACES UNAVAILABLE"
        color: Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }

    Row {
        id: row
        visible: root.state.available
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.state.ids

            Button {
                id: button

                required property int modelData
                readonly property bool current: root.state.activeWorkspaceId(root.outputName) === modelData
                readonly property bool occupied: root.state.occupied(modelData)
                readonly property bool urgent: (attentionPending || root.state.urgent(modelData)) && !current
                readonly property bool muted: root.state.muted(modelData)
                property bool attentionPending: false
                property real attentionOpacity: 0

                width: (current ? 30 : 22) + (muted ? 12 : 0)
                height: 22
                padding: 0
                hoverEnabled: true
                Accessible.name: "Workspace " + modelData + (current ? ", active" : urgent ? ", needs attention" : occupied ? ", occupied" : ", empty")
                    + (muted ? ", muted" : "")
                Accessible.role: Accessible.Button

                onCurrentChanged: {
                    if (current) {
                        attentionPending = false
                        attentionAnimation.stop()
                        attentionOpacity = 0
                    }
                }

                onOccupiedChanged: {
                    if (!occupied) {
                        attentionPending = false
                        attentionAnimation.stop()
                        attentionOpacity = 0
                    }
                }

                Connections {
                    target: root.state

                    function onAttentionRequested(workspaceId) {
                        if (workspaceId === button.modelData && !button.current) {
                            button.attentionPending = true
                            attentionAnimation.restart()
                        }
                    }
                }

                SequentialAnimation {
                    id: attentionAnimation
                    loops: 3

                    NumberAnimation {
                        target: button
                        property: "attentionOpacity"
                        from: 0
                        to: 1
                        duration: 280
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: button
                        property: "attentionOpacity"
                        from: 1
                        to: 0
                        duration: 420
                        easing.type: Easing.InOutSine
                    }
                }

                contentItem: Item {
                    id: label
                    readonly property color tint: button.current || button.attentionOpacity > 0.5 ? Theme.textOnAccent
                        : button.urgent ? Theme.accent
                        : button.occupied ? Theme.text : Theme.textDisabled

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: button.modelData
                            color: label.tint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.features: { "tnum": 1 }
                        }

                        ShellIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: button.muted
                            width: 10
                            height: 10
                            name: "volume-x"
                            tint: label.tint
                        }
                    }
                }

                background: Rectangle {
                    color: button.current ? Theme.accent
                        : button.urgent ? (button.down ? Theme.selectedPressedSurface : button.hovered ? Theme.selectedHoverSurface : Theme.selectedSurface)
                        : button.hovered || button.down ? Theme.surfaceRaised : "transparent"
                    border.color: button.current || button.urgent ? Theme.accent : button.occupied ? Theme.borderInteractive : Theme.border
                    border.width: button.urgent ? Theme.focusWidth : Theme.borderWidth
                    radius: height / 2

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.accent
                        opacity: button.attentionOpacity
                    }
                }

                onClicked: root.state.activate(modelData)

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: root.openMenu(button.modelData, button)
                }
            }
        }
    }

    PopupWindow {
        id: menu

        readonly property bool muted: root.state.muted(root.menuWorkspaceId)

        visible: false
        color: "transparent"
        grabFocus: true
        implicitWidth: 200
        implicitHeight: Theme.controlHeight + Theme.spaceMd * 2

        anchor {
            id: popupAnchor
            window: root.menuAnchor ? root.menuAnchor.QsWindow.window : null
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            adjustment: PopupAdjustment.Slide
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                if (!root.menuAnchor) return
                const window = root.menuAnchor.QsWindow.window
                if (!window) return
                const point = window.contentItem.mapFromItem(root.menuAnchor, 0, root.menuAnchor.height + Theme.panelGap)
                popupAnchor.rect.x = Math.round(point.x)
                popupAnchor.rect.y = Math.round(point.y)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.selectedSurface
            border.color: Theme.borderInteractive
            border.width: Theme.borderWidth
            radius: Theme.radius
            focus: true

            Keys.onEscapePressed: menu.visible = false

            Rectangle {
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                radius: Theme.radius
                color: muteMouse.containsMouse ? Theme.selectedHoverSurface : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceMd
                    spacing: Theme.spaceMd

                    ShellIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        name: menu.muted ? "volume-2" : "volume-x"
                        tint: Theme.text
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (menu.muted ? "Unmute" : "Mute") + " workspace " + root.menuWorkspaceId
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.state.toggleMute(root.menuWorkspaceId)
                        menu.visible = false
                    }
                }
            }
        }
    }
}
