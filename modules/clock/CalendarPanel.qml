pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    property var coordinator: null
    property var clockState: null
    property date visibleMonth: new Date()
    property date selectedDate: new Date()
    property string reminderTime: ""
    property string formMessage: ""
    property bool formSucceeded: false

    readonly property date today: clockState ? clockState.now : new Date()
    readonly property int year: visibleMonth.getFullYear()
    readonly property int month: visibleMonth.getMonth()
    readonly property int firstDayOffset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property int remindersRevision: clockState ? clockState.remindersRevision : 0
    readonly property var selectedReminders: {
        const revision = root.remindersRevision
        return root.clockState ? root.clockState.remindersForDate(root.selectedDate) : []
    }
    readonly property date requestedReminderDate: reminderDateTime()
    readonly property bool canAddReminder: clockState
        && clockState.reminderStorageReady
        && reminderField.text.trim() !== ""
        && !Number.isNaN(requestedReminderDate.getTime())
        && requestedReminderDate.getTime() > Date.now()

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    function moveMonth(delta) {
        visibleMonth = new Date(year, month + delta, 1)
    }

    function dayForCell(cell) {
        const day = cell - firstDayOffset + 1
        return day >= 1 && day <= daysInMonth ? day : 0
    }

    function dateForDay(day) {
        return new Date(year, month, day)
    }

    function isToday(day) {
        return day > 0
            && today.getFullYear() === year
            && today.getMonth() === month
            && today.getDate() === day
    }

    function isSelected(day) {
        return day > 0
            && selectedDate.getFullYear() === year
            && selectedDate.getMonth() === month
            && selectedDate.getDate() === day
    }

    function selectDay(day) {
        if (day <= 0) return
        selectedDate = dateForDay(day)
        formMessage = ""
        reminderField.forceActiveFocus()
    }

    function reminderDateTime() {
        const match = /^(\d{2}):(\d{2})$/.exec(reminderTime.trim())
        if (!match) return new Date(NaN)
        const hours = Number(match[1])
        const minutes = Number(match[2])
        if (hours > 23 || minutes > 59) return new Date(NaN)
        return new Date(
            selectedDate.getFullYear(),
            selectedDate.getMonth(),
            selectedDate.getDate(),
            hours,
            minutes,
            0,
            0
        )
    }

    function addReminder() {
        formSucceeded = false
        if (!clockState || !clockState.reminderStorageReady) {
            formMessage = "Reminder storage is unavailable"
            return
        }
        if (reminderField.text.trim() === "") {
            formMessage = "Enter reminder text"
            return
        }
        const when = reminderDateTime()
        if (Number.isNaN(when.getTime())) {
            formMessage = "Use a valid 24-hour time"
            return
        }
        if (when.getTime() <= Date.now()) {
            formMessage = "Choose a future time"
            return
        }
        if (!clockState.addReminder(when, reminderField.text)) {
            formMessage = "Could not save reminder"
            return
        }
        reminderField.text = ""
        formSucceeded = true
        formMessage = "Reminder saved"
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
                    readonly property bool selected: root.isSelected(day)
                    readonly property bool hasReminder: root.remindersRevision >= 0
                        && day > 0
                        && root.clockState
                        && root.clockState.hasReminderOnDate(root.dateForDay(day))

                    width: 44
                    height: 40
                    color: selected ? Theme.accent : current ? Theme.surfaceRaised : "transparent"
                    border.color: selected || current ? Theme.accent : "transparent"
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.day > 0 ? dayCell.day : ""
                        color: dayCell.selected ? Theme.textOnAccent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: dayCell.current || dayCell.selected
                    }

                    Rectangle {
                        visible: dayCell.hasReminder
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 3
                        }
                        width: 4
                        height: 4
                        radius: 2
                        color: dayCell.selected ? Theme.textOnAccent : Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: dayCell.day > 0
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        Accessible.name: enabled ? "Select " + Qt.formatDate(root.dateForDay(dayCell.day), "dddd, dd MMMM yyyy") : ""
                        Accessible.role: Accessible.Button
                        onClicked: root.selectDay(dayCell.day)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }

        Text {
            width: parent.width
            text: "REMINDER · " + Qt.formatDate(root.selectedDate, "dddd, dd MMMM yyyy").toUpperCase()
            color: Theme.accentMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            height: Theme.rowHeight
            spacing: Theme.spaceMd

            TextField {
                id: timeField
                width: 82
                height: parent.height
                text: root.reminderTime
                onTextChanged: {
                    root.reminderTime = text
                    root.formMessage = ""
                }
                placeholderText: "HH:MM"
                maximumLength: 5
                inputMethodHints: Qt.ImhDigitsOnly
                color: Theme.text
                placeholderTextColor: Theme.textMuted
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Text.AlignHCenter
                Accessible.name: "Reminder time in 24-hour format"

                background: Rectangle {
                    color: Theme.surfaceRaised
                    border.color: timeField.activeFocus ? Theme.focus : Theme.borderInteractive
                    border.width: timeField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                    radius: Theme.radius
                }
            }

            TextField {
                id: reminderField
                width: parent.width - timeField.width - parent.spacing
                height: parent.height
                placeholderText: "Reminder text"
                color: Theme.text
                placeholderTextColor: Theme.textMuted
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                leftPadding: Theme.spaceLg
                rightPadding: Theme.spaceLg
                Accessible.name: "Reminder text"
                onTextChanged: root.formMessage = ""
                onAccepted: root.addReminder()

                background: Rectangle {
                    color: Theme.surfaceRaised
                    border.color: reminderField.activeFocus ? Theme.focus : Theme.borderInteractive
                    border.width: reminderField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                    radius: Theme.radius
                }
            }
        }

        ActionButton {
            width: parent.width
            text: "SET REMINDER"
            selected: true
            enabled: root.canAddReminder
            accessibleName: "Set reminder"
            onClicked: root.addReminder()
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.clockState && root.clockState.reminderError !== ""
                ? root.clockState.reminderError : root.formMessage
            color: root.formSucceeded ? Theme.accent : Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: root.selectedReminders.length > 0
            text: "SCHEDULED"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
        }

        ListView {
            id: reminderList
            width: parent.width
            height: visible ? Math.min(contentHeight, 120) : 0
            visible: root.selectedReminders.length > 0
            clip: true
            spacing: Theme.spaceSm
            model: root.selectedReminders

            delegate: Rectangle {
                id: reminderRow
                required property var modelData

                width: reminderList.width
                height: Theme.rowHeight
                color: Theme.surfaceRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radius

                Row {
                    anchors {
                        fill: parent
                        leftMargin: Theme.spaceMd
                        rightMargin: Theme.spaceSm
                    }
                    spacing: Theme.spaceMd

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 46
                        text: Qt.formatTime(new Date(reminderRow.modelData.at), "HH:mm")
                        color: reminderRow.modelData.fired ? Theme.textMuted : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 46 - deleteButton.width - parent.spacing * 2
                        text: reminderRow.modelData.text
                        textFormat: Text.PlainText
                        color: reminderRow.modelData.fired ? Theme.textMuted : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.strikeout: reminderRow.modelData.fired
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        id: deleteButton
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.compactControlSize
                        text: "×"
                        danger: true
                        accessibleName: "Delete reminder " + reminderRow.modelData.text
                        onClicked: root.clockState.removeReminder(reminderRow.modelData.id)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        const initial = new Date(today.getTime() + 60 * 60 * 1000)
        initial.setSeconds(0, 0)
        selectedDate = new Date(initial.getFullYear(), initial.getMonth(), initial.getDate())
        visibleMonth = new Date(initial.getFullYear(), initial.getMonth(), 1)
        reminderTime = Qt.formatTime(initial, "HH:mm")
        previousButton.forceActiveFocus()
    }
}
