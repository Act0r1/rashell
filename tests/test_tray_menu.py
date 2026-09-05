import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class TrayMenuThemeTests(unittest.TestCase):
    def test_tray_menu_is_rendered_by_rashell_instead_of_native_qt(self) -> None:
        tray_bar = (ROOT / "modules/system/TrayBar.qml").read_text()
        tray_menu_path = ROOT / "modules/system/TrayMenu.qml"

        self.assertNotIn("modelData.display(", tray_bar)
        self.assertTrue(tray_menu_path.exists())

        tray_menu = tray_menu_path.read_text()
        self.assertIn("QsMenuOpener", tray_menu)
        self.assertIn("color: root.accentTintedSurface", tray_menu)
        self.assertIn("color: Theme.text", tray_menu)
        self.assertIn("Theme.surfaceRaised", tray_menu)
        self.assertIn("readonly property color accentTintedSurface", tray_menu)
        self.assertIn("readonly property color accentTintedHover", tray_menu)
        self.assertIn("border.color: root.accentTintedBorder", tray_menu)


if __name__ == "__main__":
    unittest.main()
