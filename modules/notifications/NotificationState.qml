import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: state

    required property var configStore

    property int unread: 0
    property bool doNotDisturb: false
    property var latest: null
    property string popupAppName: ""
    property string popupSummary: ""
    property string popupBody: ""
    property bool popupVisible: false
    property bool popupHeld: false
    property real popupProgress: 0
    property real popupDeadlineMs: 0
    property int popupRemainingMs: 0
    property int popupTotalDurationMs: 0
    property var popupQueue: []
    property ListModel history: ListModel {}
    readonly property int popupDurationSeconds: configStore
        ? configStore.notificationDurationSeconds : 8

    function receive(notification) {
        const appName = String(notification.appName || "").trim()
        const summary = String(notification.summary || "").trim()
        const body = String(notification.body || "").trim()
        if (appName === "" && summary === "" && body === "") return

        notification.tracked = true
        history.insert(0, {
            notification: notification,
            appName: appName || "Notification",
            summary: summary,
            body: body,
            time: Qt.formatTime(new Date(), "HH:mm"),
            isUnread: true
        })
        if (history.count > 50) {
            const removed = history.get(history.count - 1)
            if (removed.isUnread) unread = Math.max(0, unread - 1)
            removeQueuedNotification(removed.notification)
            history.remove(history.count - 1)
        }
        unread += 1
        if (!doNotDisturb) {
            if (popupVisible) popupQueue = popupQueue.concat([notification])
            else showPopup(notification)
        }
    }

    function showPopup(notification) {
        latest = notification
        popupAppName = String(notification.appName || "Notification")
        popupSummary = String(notification.summary || "")
        popupBody = String(notification.body || "")
        popupTotalDurationMs = popupDurationSeconds * 1000
        popupRemainingMs = popupTotalDurationMs
        popupDeadlineMs = Date.now() + popupRemainingMs
        popupProgress = 1
        popupHeld = false
        popupVisible = true
        popupCountdown.restart()
    }

    function removeQueuedNotification(notification) {
        popupQueue = popupQueue.filter(queued => queued !== notification)
    }

    function dismiss(index) {
        if (index < 0 || index >= history.count) return
        const item = history.get(index)
        if (item.isUnread) unread = Math.max(0, unread - 1)
        removeQueuedNotification(item.notification)
        if (item.notification) item.notification.dismiss()
        history.remove(index)
    }

    function clear() {
        while (history.count > 0) dismiss(0)
        unread = 0
    }

    function markRead() {
        for (let index = 0; index < history.count; index++) history.setProperty(index, "isUnread", false)
        unread = 0
    }

    function markNotificationRead(notification) {
        for (let index = 0; index < history.count; index++) {
            const item = history.get(index)
            if (item.notification === notification && item.isUnread) {
                history.setProperty(index, "isUnread", false)
                unread = Math.max(0, unread - 1)
                return
            }
        }
    }

    function dismissNotification(notification) {
        for (let index = 0; index < history.count; index++) {
            if (history.get(index).notification === notification) {
                dismiss(index)
                return
            }
        }
        if (notification) notification.dismiss()
    }

    function invokeAction(notification, action) {
        if (!notification || !action) return
        markNotificationRead(notification)
        action.invoke()
    }

    function sendReply(notification, text) {
        const reply = String(text).trim()
        if (!notification || reply === "") return false
        markNotificationRead(notification)
        notification.sendInlineReply(reply)
        return true
    }

    function setPopupDurationSeconds(seconds) {
        return configStore.setNotificationDurationSeconds(seconds)
    }

    function hidePopup() {
        popupCountdown.stop()
        popupVisible = false
        popupHeld = false
        popupProgress = 0
        popupRemainingMs = 0
        if (popupQueue.length === 0) return
        showPopup(popupQueue[0])
        popupQueue = popupQueue.slice(1)
    }

    function holdPopup() {
        if (!popupVisible || popupHeld) return
        popupRemainingMs = Math.max(0, Math.round(popupDeadlineMs - Date.now()))
        popupCountdown.stop()
        popupHeld = true
    }

    function resumePopup() {
        if (!popupVisible || !popupHeld) return
        popupDeadlineMs = Date.now() + popupRemainingMs
        popupHeld = false
        popupCountdown.start()
    }

    NotificationServer {
        keepOnReload: false
        imageSupported: false
        actionsSupported: true
        inlineReplySupported: true
        onNotification: notification => state.receive(notification)
    }

    Timer {
        id: popupCountdown
        interval: 16
        repeat: true
        onTriggered: {
            state.popupRemainingMs = Math.max(0, Math.round(state.popupDeadlineMs - Date.now()))
            state.popupProgress = state.popupTotalDurationMs > 0
                ? state.popupRemainingMs / state.popupTotalDurationMs : 0
            if (state.popupRemainingMs === 0) state.hidePopup()
        }
    }
}
