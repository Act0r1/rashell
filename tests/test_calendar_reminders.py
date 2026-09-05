import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CalendarReminderTest(unittest.TestCase):
    def test_reminders_are_persisted_and_delivered(self) -> None:
        state = (ROOT / "modules/clock/ClockState.qml").read_text()

        self.assertIn("reminders.json", state)
        self.assertIn("FileView", state)
        self.assertIn("function addReminder", state)
        self.assertIn("function removeReminder", state)
        self.assertIn('"notify-send"', state)
        self.assertIn("checkReminders", state)

    def test_calendar_can_create_and_delete_reminders(self) -> None:
        panel = (ROOT / "modules/clock/CalendarPanel.qml").read_text()

        self.assertIn("TextField", panel)
        self.assertIn("SET REMINDER", panel)
        self.assertIn("clockState.addReminder", panel)
        self.assertIn("clockState.removeReminder", panel)
        self.assertIn("root.selectDay", panel)


if __name__ == "__main__":
    unittest.main()
