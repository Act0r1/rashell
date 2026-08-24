pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core

Item {
    id: root

    property Item anchorItem: null
    property bool open: false
    property date visibleMonth: new Date()
    readonly property date today: new Date()
    readonly property int year: visibleMonth.getFullYear()
    readonly property int month: visibleMonth.getMonth()
    readonly property int firstDayOffset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    function moveMonth(delta) {
        visibleMonth = new Date(year, month + delta, 1)
    }

    function dayForCell(cell) {
        const day = cell - firstDayOffset + 1
        return day >= 1 && day <= daysInMonth ? day : 0
    }

    function isToday(day) {
        return day > 0
            && today.getFullYear() === year
            && today.getMonth() === month
            && today.getDate() === day
    }

    component NavButton: Rectangle {
        id: button

        required property string label
        signal pressed()

        width: 30
        height: 30
        color: hover.hovered ? Theme.surfaceRaised : "transparent"
        border.color: Theme.border
        border.width: 1
        radius: Theme.radius

        Text {
            anchors.centerIn: parent
            text: button.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        HoverHandler {
            id: hover
        }

        TapHandler {
            onTapped: button.pressed()
        }
    }

    PopupWindow {
        id: popup

        visible: root.open && root.anchorItem !== null
        color: "transparent"
        implicitWidth: 360
        implicitHeight: 390

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
                    root.anchorItem.width / 2 - popup.implicitWidth / 2,
                    root.anchorItem.height + Theme.panelGap
                )
                popupAnchor.rect.x = Math.round(point.x)
                popupAnchor.rect.y = Math.round(point.y)
            }
        }

        Shortcut {
            sequence: "Esc"
            onActivated: root.open = false
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius

            Column {
                anchors {
                    fill: parent
                    margins: Theme.panelPadding
                }
                spacing: 12

                Row {
                    width: parent.width

                    NavButton {
                        label: "<"
                        onPressed: root.moveMonth(-1)
                    }

                    Item {
                        width: parent.width - 60
                        height: 30

                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDate(root.visibleMonth, "MMMM yyyy").toUpperCase()
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }

                    NavButton {
                        label: ">"
                        onPressed: root.moveMonth(1)
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    spacing: 2

                    Repeater {
                        model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

                        Item {
                            required property string modelData
                            width: 44
                            height: 26

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                            }
                        }
                    }

                    Repeater {
                        model: 42

                        Rectangle {
                            id: dayCell

                            required property int modelData
                            readonly property int day: root.dayForCell(modelData)
                            readonly property bool current: root.isToday(day)

                            width: 44
                            height: 40
                            color: current ? Theme.accent : dayHover.hovered && day > 0
                                ? Theme.surfaceRaised : "transparent"
                            border.color: current ? Theme.accent : "transparent"
                            border.width: 1
                            radius: Theme.radius

                            Text {
                                anchors.centerIn: parent
                                text: dayCell.day > 0 ? dayCell.day : ""
                                color: dayCell.current ? Theme.background
                                    : dayCell.day > 0 ? Theme.text : "transparent"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: dayCell.current
                            }

                            HoverHandler {
                                id: dayHover
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.today, "dddd, dd MMMM yyyy")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
