pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    property var coordinator: null
    property var clockState: null
    property date visibleMonth: new Date()
    readonly property date today: clockState ? clockState.now : new Date()
    readonly property int year: visibleMonth.getFullYear()
    readonly property int month: visibleMonth.getMonth()
    readonly property int firstDayOffset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

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

    Shortcut {
        sequence: "Esc"
        onActivated: if (root.coordinator) root.coordinator.close("escape")
    }

    PanelFrame {
        id: frame
        anchors.fill: parent
        title: "Calendar"
        contentWidth: 360
        onCloseRequested: if (root.coordinator) root.coordinator.close("close-control")

        Row {
            width: parent.width

            ActionButton {
                id: previousButton
                text: "<"
                accessibleName: "Previous month"
                KeyNavigation.right: nextButton
                onClicked: root.moveMonth(-1)
            }

            Item {
                width: parent.width - previousButton.width - nextButton.width
                height: Theme.compactControlSize

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

            ActionButton {
                id: nextButton
                text: ">"
                accessibleName: "Next month"
                KeyNavigation.left: previousButton
                onClicked: root.moveMonth(1)
            }
        }

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            spacing: Theme.spaceXs

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
                    color: current ? Theme.accent : "transparent"
                    border.color: current ? Theme.accent : "transparent"
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.day > 0 ? dayCell.day : ""
                        color: dayCell.current ? Theme.textOnAccent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: dayCell.current
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

    Component.onCompleted: {
        visibleMonth = new Date(today.getFullYear(), today.getMonth(), 1)
        previousButton.forceActiveFocus()
    }
}
