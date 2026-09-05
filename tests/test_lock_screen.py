import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class LockScreenTest(unittest.TestCase):
    def test_lock_screen_uses_session_lock_and_pam(self) -> None:
        screen = (ROOT / "modules/lock/LockScreen.qml").read_text()
        context = (ROOT / "modules/lock/LockContext.qml").read_text()

        self.assertIn("WlSessionLock", screen)
        self.assertIn("WlSessionLockSurface", screen)
        self.assertIn("PamContext", context)
        self.assertIn('config: "swaylock"', context)
        self.assertIn("Enter your password", screen)

    def test_control_center_uses_the_rashell_lock_screen(self) -> None:
        panel = (ROOT / "modules/system/ControlPanel.qml").read_text()

        self.assertIn("const lock = root.lockScreen", panel)
        self.assertIn("lock.lock()", panel)
        self.assertIn("lock.lockAndSuspend()", panel)
        self.assertNotIn("swaylock", panel)

    def test_icon_buttons_have_hover_descriptions(self) -> None:
        button = (ROOT / "ui/ActionButton.qml").read_text()

        self.assertIn("property string toolTipText: accessibleName", button)
        self.assertIn("control.hovered", button)


if __name__ == "__main__":
    unittest.main()
