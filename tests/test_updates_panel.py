import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class UpdatesPanelTest(unittest.TestCase):
    def test_updates_button_opens_themed_panel(self) -> None:
        bar_source = (ROOT / "modules/system/UpdatesBar.qml").read_text()
        slot_source = (ROOT / "bar/ModuleSlot.qml").read_text()

        self.assertIn('root.coordinator.toggle(', bar_source)
        self.assertIn('/modules/system/UpdatesPanel.qml', bar_source)
        self.assertNotIn('Quickshell.execDetached', bar_source)
        self.assertIn('coordinator: root.coordinator', slot_source)
        self.assertIn('outputName: root.outputName', slot_source)

    def test_updates_panel_shows_versions_and_actions(self) -> None:
        panel_source = (ROOT / "modules/system/UpdatesPanel.qml").read_text()
        state_source = (ROOT / "modules/system/SystemState.qml").read_text()

        self.assertIn('currentVersion + "  →  " + newVersion', panel_source)
        self.assertIn('text: "Refresh"', panel_source)
        self.assertIn('text: "Update"', panel_source)
        self.assertIn('onClicked: root.systemState.refreshUpdates()', panel_source)
        self.assertIn('root.systemState.availableUpdates', panel_source)
        self.assertIn('currentVersion: match[2]', state_source)
        self.assertIn('newVersion: match[3]', state_source)


if __name__ == "__main__":
    unittest.main()
