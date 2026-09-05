pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Rectangle {
    id: root

    required property var colors
    required property var metrics
    required property string wallpaper
    required property string themeName

    color: colors.background
    border.color: colors.borderInteractive
    border.width: 1
    radius: 12
    clip: true

    Image {
        anchors.fill: parent
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 1200
        asynchronous: true
        opacity: 0.38
    }

    Rectangle {
        anchors.fill: parent
        color: root.colors.background
        opacity: 0.25
    }

    Rectangle {
        id: previewBar
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.metrics.barHeight
        color: root.colors.surface

        Row {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 12
            Repeater {
                model: ["01", "02", "03"]
                Text {
                    required property string modelData
                    text: modelData
                    color: modelData === "01" ? root.colors.accent : root.colors.textMuted
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSmall; bold: modelData === "01" }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "14:32"
            color: root.colors.text
            font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
        }

        Text {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: "󰖩   󰕾  60%"
            color: root.colors.accent
            font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: root.colors.border
        }
    }

    Rectangle {
        id: terminal
        x: 24
        y: previewBar.height + 28
        width: Math.min(root.width - 48, root.width * 0.72)
        height: Math.max(140, root.height - previewBar.height - 62)
        color: root.colors.surface
        radius: root.metrics.radius
        border.color: root.colors.borderInteractive
        border.width: 1

        Column {
            anchors { fill: parent; margins: 18 }
            spacing: 14

            Row {
                width: parent.width
                spacing: 8
                Rectangle { width: 7; height: 7; radius: 4; color: root.colors.accent; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Terminal"
                    color: root.colors.textMuted
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.colors.border }

            Text {
                width: parent.width
                text: "insaf ~"
                color: root.colors.accent
                font { family: Theme.fontFamily; pixelSize: Theme.fontBody; bold: true }
            }

            Text {
                width: parent.width
                text: root.themeName
                color: root.colors.text
                font { family: Theme.fontFamily; pixelSize: Theme.fontTitle; bold: true }
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: terminal.height > 190
                text: "A little space to build."
                color: root.colors.textMuted
                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
                elide: Text.ElideRight
            }

            Row {
                spacing: 5
                Repeater {
                    model: ["accent", "accentMuted", "text", "textMuted", "danger"]
                    Rectangle {
                        required property string modelData
                        width: 22
                        height: 12
                        radius: 2
                        color: root.colors[modelData]
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 24 }
        width: Math.min(245, root.width - 64)
        height: 112
        color: root.colors.surfaceRaised
        radius: root.metrics.radius
        border.color: root.colors.borderInteractive
        border.width: 1
        visible: root.width > 340 && root.height > 240

        Column {
            anchors { fill: parent; margins: 14 }
            spacing: 9

            Text {
                text: "󰂚  Notification"
                color: root.colors.accent
                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall; bold: true }
            }
            Text {
                text: "Everything in its place."
                color: root.colors.text
                font { family: Theme.fontFamily; pixelSize: Theme.fontSmall }
            }
            Rectangle {
                width: 78
                height: 25
                color: root.colors.accent
                radius: root.metrics.radius
                Text {
                    anchors.centerIn: parent
                    text: "Open"
                    color: root.colors.textOnAccent
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSmall; bold: true }
                }
            }
        }
    }
}
