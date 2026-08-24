pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.core

Item {
    id: root
    implicitWidth: trayRow.implicitWidth
    implicitHeight: Theme.controlHeight
    visible: SystemTray.items && SystemTray.items.values.length > 0

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: SystemTray.items ? SystemTray.items.values : []

            Item {
                id: trayItem
                required property var modelData
                width: 28
                height: Theme.controlHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: mouse.containsMouse ? Theme.surfaceRaised : "transparent"
                }

                Image {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: Quickshell.iconPath(trayItem.modelData.icon)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            trayItem.modelData.activate()
                        } else if (event.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate()
                        } else {
                            const window = trayItem.QsWindow.window
                            const point = trayItem.mapToItem(window.contentItem, event.x, event.y)
                            trayItem.modelData.display(window, Math.round(point.x), Math.round(point.y))
                        }
                    }
                }
            }
        }
    }
}
