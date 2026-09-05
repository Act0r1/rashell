import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class NetworkPanelTest(unittest.TestCase):
    def test_network_settings_use_themed_rashell_panel(self) -> None:
        control_panel = (ROOT / "modules/system/ControlPanel.qml").read_text()
        control_state = (ROOT / "modules/system/ControlState.qml").read_text()
        network_panel_path = ROOT / "modules/system/NetworkPanel.qml"

        self.assertIn('"/modules/system/NetworkPanel.qml"', control_panel)
        self.assertNotIn("nm-connection-editor", control_state)
        self.assertTrue(network_panel_path.exists())

        network_panel = network_panel_path.read_text()
        self.assertIn("PanelFrame", network_panel)
        self.assertIn("Quickshell.Networking", network_panel)
        self.assertIn("Theme.surfaceRaised", network_panel)
        self.assertIn("connectWithPsk", network_panel)


if __name__ == "__main__":
    unittest.main()
