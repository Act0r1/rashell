pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
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

                function iconSource() {
                    const icon = String(modelData.icon || "")
                    if (!icon.includes("?path=")) return icon
                    const chunks = icon.split("?path=")
                    const fileName = chunks[0].substring(chunks[0].lastIndexOf("/") + 1)
                    return "file://" + chunks[1] + "/" + fileName
                }

                function displayMenu(x, y) {
                    if (!modelData.hasMenu) return
                    const window = trayItem.QsWindow.window
                    const point = trayItem.mapToItem(window.contentItem, x, y)
                    modelData.display(window, Math.round(point.x), Math.round(point.y))
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: mouse.containsMouse ? Theme.surfaceRaised : "transparent"
                }

                IconImage {
                    id: icon
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: trayItem.iconSource()
                    asynchronous: true
                    backer.fillMode: Image.PreserveAspectFit
                    opacity: status === Image.Ready ? 1 : 0
                }

                Text {
                    anchors.centerIn: parent
                    visible: icon.status === Image.Error
                    text: "·"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            if (trayItem.modelData.onlyMenu) trayItem.displayMenu(event.x, event.y)
                            else trayItem.modelData.activate()
                        } else if (event.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate()
                        } else {
                            trayItem.displayMenu(event.x, event.y)
                        }
                    }
                }
            }
        }
    }
}
