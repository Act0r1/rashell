import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class NotificationActionsTest(unittest.TestCase):
    def test_notification_server_advertises_actions_and_inline_replies(self) -> None:
        state = (ROOT / "modules/notifications/NotificationState.qml").read_text()

        self.assertIn("actionsSupported: true", state)
        self.assertIn("inlineReplySupported: true", state)
        self.assertIn("action.invoke()", state)
        self.assertIn("notification.sendInlineReply(reply)", state)

    def test_panel_and_popup_render_notification_actions(self) -> None:
        actions = (ROOT / "modules/notifications/NotificationActions.qml").read_text()
        panel = (ROOT / "modules/notifications/NotificationPanel.qml").read_text()
        popup = (ROOT / "modules/notifications/NotificationPopup.qml").read_text()

        self.assertIn("model: root.availableActions", actions)
        self.assertIn("? notification.actions : []", actions)
        self.assertIn('text: "REPLY"', actions)
        self.assertIn("onAccepted: root.submitReply()", actions)
        self.assertIn("NotificationActions {", panel)
        self.assertIn("NotificationActions {", popup)
        self.assertIn("? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None", popup)

    def test_popup_duration_is_configurable_and_has_progress_bar(self) -> None:
        state = (ROOT / "modules/notifications/NotificationState.qml").read_text()
        panel = (ROOT / "modules/notifications/NotificationPanel.qml").read_text()
        popup = (ROOT / "modules/notifications/NotificationPopup.qml").read_text()
        config_store = (ROOT / "core/ConfigStore.qml").read_text()

        self.assertIn("notificationDurationSeconds: 8", config_store)
        self.assertIn("popupDeadlineMs = Date.now() + popupRemainingMs", state)
        self.assertIn("popupCountdown.start()", state)
        self.assertIn('text: "POPUP TIME"', panel)
        self.assertIn("root.notificationState.popupProgress", popup)

    def test_sender_close_does_not_hide_popup_early(self) -> None:
        state = (ROOT / "modules/notifications/NotificationState.qml").read_text()
        popup = (ROOT / "modules/notifications/NotificationPopup.qml").read_text()

        self.assertIn("popupAppName = String(notification.appName", state)
        self.assertIn("visible: root.notificationState.popupVisible", popup)
        self.assertNotIn("popupVisible && root.notificationState.latest !== null", popup)
        self.assertIn("root.notificationState.popupAppName", popup)

    def test_empty_notifications_are_ignored(self) -> None:
        state = (ROOT / "modules/notifications/NotificationState.qml").read_text()

        self.assertIn('if (appName === "" && summary === "" && body === "") return', state)
        self.assertLess(state.index('if (appName === ""'), state.index("notification.tracked = true"))

    def test_popup_notifications_are_queued_instead_of_replacing_each_other(self) -> None:
        state = (ROOT / "modules/notifications/NotificationState.qml").read_text()

        self.assertIn("property var popupQueue: []", state)
        self.assertIn("popupQueue = popupQueue.concat([notification])", state)
        self.assertIn("showPopup(popupQueue[0])", state)


if __name__ == "__main__":
    unittest.main()
