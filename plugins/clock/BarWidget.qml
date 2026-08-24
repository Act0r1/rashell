import QtQuick
import qs.core

Item {
    id: root

    property var manifest: null
    property var pluginRegistry: null
    property date now: new Date()

    implicitWidth: 150
    implicitHeight: Theme.controlHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: clockHover.hovered || (panelLoader.item && panelLoader.item.open)
            ? Theme.surfaceRaised : "transparent"
        border.color: panelLoader.item && panelLoader.item.open ? Theme.accent : "transparent"
        border.width: 1
        radius: Theme.radius

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.now, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.now, "ddd, MMM dd").toUpperCase()
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.letterSpacing: 1.5
            }
        }

        HoverHandler {
            id: clockHover
        }

        TapHandler {
            onTapped: {
                if (panelLoader.item) panelLoader.item.open = !panelLoader.item.open
            }
        }
    }

    Loader {
        id: panelLoader
        active: true
        source: "Panel.qml"
        onLoaded: item.anchorItem = root
    }
}
