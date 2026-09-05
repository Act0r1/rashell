import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: state

    property date now: new Date()
    property var reminders: []
    property int remindersRevision: 0
    property bool reminderStorageReady: false
    property string reminderError: ""

    readonly property string stateHome: String(Quickshell.env("XDG_STATE_HOME")
        || (Quickshell.env("HOME") + "/.local/state"))
    readonly property string storageDirectory: stateHome + "/rashell"
    readonly property string storagePath: storageDirectory + "/reminders.json"

    function reminderRecord(id, at, text, fired) {
        return {
            id: String(id),
            at: Number(at),
            text: String(text),
            fired: fired === true
        }
    }

    function replaceReminders(next) {
        reminders = next
        remindersRevision += 1
    }

    function loadReminders(text) {
        try {
            const parsed = JSON.parse(String(text || "[]"))
            if (!Array.isArray(parsed)) throw new Error("expected an array")

            const valid = []
            for (let index = 0; index < parsed.length; index++) {
                const item = parsed[index]
                const at = Number(item.at)
                const reminderText = String(item.text || "").trim()
                if (!item || String(item.id || "") === "" || !Number.isFinite(at) || reminderText === "") continue
                valid.push(reminderRecord(item.id, at, reminderText, item.fired))
            }
            valid.sort((left, right) => left.at - right.at)
            replaceReminders(valid)
            reminderStorageReady = true
            reminderError = ""
            checkReminders()
        } catch (error) {
            reminderStorageReady = false
            reminderError = "Could not load reminders: " + error
        }
    }

    function persistReminders() {
        if (!reminderStorageReady) return false
        reminderFile.setText(JSON.stringify(reminders, null, 2) + "\n")
        return true
    }

    function addReminder(when, text) {
        const at = when instanceof Date ? when.getTime() : Number(when)
        const reminderText = String(text || "").trim()
        if (!reminderStorageReady || !Number.isFinite(at) || at <= Date.now() || reminderText === "") return false

        const next = Array.from(reminders)
        next.push(reminderRecord(Date.now() + "-" + Math.random().toString(16).slice(2), at, reminderText, false))
        next.sort((left, right) => left.at - right.at)
        replaceReminders(next)
        return persistReminders()
    }

    function removeReminder(id) {
        const reminderId = String(id)
        const next = reminders.filter(item => item.id !== reminderId)
        if (next.length === reminders.length) return false
        replaceReminders(next)
        return persistReminders()
    }

    function remindersForDate(date) {
        if (!(date instanceof Date) || Number.isNaN(date.getTime())) return []
        return reminders.filter(item => {
            const reminderDate = new Date(item.at)
            return reminderDate.getFullYear() === date.getFullYear()
                && reminderDate.getMonth() === date.getMonth()
                && reminderDate.getDate() === date.getDate()
        })
    }

    function hasReminderOnDate(date) {
        return remindersForDate(date).length > 0
    }

    function checkReminders() {
        if (!reminderStorageReady || reminders.length === 0) return

        const currentTime = Date.now()
        let changed = false
        const next = reminders.map(item => {
            if (item.fired || item.at > currentTime) return item
            changed = true
            Quickshell.execDetached([
                "notify-send",
                "--app-name=Rashell",
                "--icon=appointment-soon",
                "Reminder · " + Qt.formatDateTime(new Date(item.at), "dd MMM HH:mm"),
                item.text
            ])
            return reminderRecord(item.id, item.at, item.text, true)
        })

        if (!changed) return
        replaceReminders(next)
        persistReminders()
    }

    Process {
        id: storageSetup
        command: ["mkdir", "-p", state.storageDirectory]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                state.reminderError = "Could not prepare reminder storage"
                return
            }
            reminderFile.path = state.storagePath
        }
    }

    FileView {
        id: reminderFile
        path: ""
        atomicWrites: true
        printErrors: false

        onLoaded: state.loadReminders(text())
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                state.reminderStorageReady = true
                state.replaceReminders([])
                setText("[]\n")
                return
            }
            state.reminderStorageReady = false
            state.reminderError = "Reminder storage unavailable: " + FileViewError.toString(error)
        }
        onSaveFailed: function(error) {
            state.reminderError = "Could not save reminders: " + FileViewError.toString(error)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: state.now = new Date()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: state.checkReminders()
    }

    Component.onCompleted: storageSetup.running = true
}
