import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PanelCoordinatorTest(unittest.TestCase):
    def test_all_panels_grab_focus_for_outside_click_dismissal(self) -> None:
        source = (ROOT / "core/PanelCoordinator.qml").read_text()

        self.assertIn("grabFocus: true", source)
        self.assertNotIn("requestGrab", source)
        self.assertNotIn("wantsGrab", source)


if __name__ == "__main__":
    unittest.main()
