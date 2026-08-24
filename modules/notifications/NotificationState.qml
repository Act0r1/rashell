import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: state

    property int unread: 0
    property bool doNotDisturb: false
    property var latest: null
    property bool popupVisible: false
    property ListModel history: ListModel {}

    function receive(notification) {
        notification.tracked = true
        history.insert(0, {
            notification: notification,
            appName: String(notification.appName || "Notification"),
            summary: String(notification.summary || ""),
            body: String(notification.body || ""),
            time: Qt.formatTime(new Date(), "HH:mm"),
            isUnread: true
        })
        if (history.count > 50) {
            const removed = history.get(history.count - 1)
            if (removed.isUnread) unread = Math.max(0, unread - 1)
            history.remove(history.count - 1)
        }
        unread += 1
        if (!doNotDisturb) {
            latest = notification
            popupVisible = true
            popupTimer.restart()
        }
    }

    function dismiss(index) {
        if (index < 0 || index >= history.count) return
        const item = history.get(index)
        if (item.isUnread) unread = Math.max(0, unread - 1)
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

    NotificationServer {
        keepOnReload: false
        imageSupported: false
        actionsSupported: false
        onNotification: notification => state.receive(notification)
    }

    Timer {
        id: popupTimer
        interval: 5000
        onTriggered: state.popupVisible = false
    }
}
