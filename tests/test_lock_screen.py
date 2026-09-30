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
        self.assertIn('config: "rashell-lock"', context)
        self.assertIn("Enter your password", screen)

    def test_wrong_password_is_instant_with_rashell_cooldown(self) -> None:
        pam = (ROOT / "modules/lock/pam/rashell-lock").read_text()
        context = (ROOT / "modules/lock/LockContext.qml").read_text()

        self.assertIn("pam_unix.so", pam)
        self.assertIn("nodelay", pam)
        self.assertIn("count < 3 ? 0", context)
        self.assertIn("Math.min(30000", context)
        self.assertIn("if (cooldownSeconds > 0)", context)
        self.assertIn("interval: 1000", context)

    def test_lock_screen_uses_ii_pixel_visual_dependencies(self) -> None:
        lock_dir = ROOT / "modules/lock"
        screen = (lock_dir / "LockScreen.qml").read_text()

        self.assertIn('path: "/usr/share/sddm/themes/ii-pixel/theme.conf"', screen)
        self.assertIn("MultiEffect", screen)
        self.assertIn("PixelDots", screen)
        self.assertIn('["systemctl", "suspend"]', screen)
        self.assertIn('["systemctl", "poweroff"]', screen)
        self.assertIn('["systemctl", "reboot"]', screen)
        self.assertNotIn("sessionModel", screen)
        self.assertNotIn("VirtualKeyboard", screen)
        self.assertTrue((lock_dir / "fonts/MaterialSymbolsRounded.ttf").is_file())
        self.assertTrue((lock_dir / "shapes/LICENSE").is_file())

    def test_lock_screen_locks_before_any_sleep(self) -> None:
        screen = (ROOT / "modules/lock/LockScreen.qml").read_text()
        sleep_lock = (ROOT / "modules/lock/SleepLock.qml").read_text()

        self.assertIn("secure: sessionLock.secure", screen)
        self.assertIn("onLockRequested: if (!root.locked) root.lock()", screen)
        self.assertIn('"--mode=delay"', sleep_lock)
        self.assertIn("running: !(root.preparingSleep && root.secure)", sleep_lock)
        self.assertIn(".Manager.PrepareForSleep (true", sleep_lock)
        self.assertIn("org.freedesktop.login1.Session.Lock", sleep_lock)

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
