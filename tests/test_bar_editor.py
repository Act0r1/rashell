import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BarEditorTest(unittest.TestCase):
    def test_control_center_opens_separate_bar_settings_window(self) -> None:
        source = (ROOT / "modules/system/ControlPanel.qml").read_text()
        button_start = source.index('accessibleName: "Open bar settings"')
        match = re.search(r"onClicked:\s*\{(.*?)\n\s*\}", source[button_start:], re.S)
        self.assertIsNotNone(match)
        handler = match.group(1)

        self.assertIn('coordinator.close("open-bar-settings")', handler)
        self.assertIn("const editor = root.barEditor", handler)
        self.assertIn("editor.open(screen)", handler)
        self.assertNotIn("coordinator.open(", handler)

    def test_editor_stages_changes_until_apply(self) -> None:
        source = (ROOT / "modules/system/BarEditorPanel.qml").read_text()

        self.assertIn("function moveTo(moduleId, targetZone)", source)
        self.assertIn("function moveWithin(moduleId, zoneName, delta)", source)
        self.assertIn("configStore.setBar(draftLeft, draftCenter, draftRight)", source)

    def test_editor_supports_drag_drop_and_immediate_escape(self) -> None:
        source = (ROOT / "modules/system/BarEditorPanel.qml").read_text()

        self.assertIn("function moveAt(moduleId, targetZone, targetIndex)", source)
        self.assertIn('Drag.keys: ["bar-widget"]', source)
        self.assertIn('keys: ["bar-widget"]', source)
        self.assertIn("root.moveAt(drop.source.moduleId", source)
        self.assertIn('sequence: "Esc"', source)
        self.assertIn("context: Qt.ApplicationShortcut", source)
        self.assertIn("onActivated: root.close()", source)

    def test_config_store_exposes_bar_update(self) -> None:
        source = (ROOT / "core/ConfigStore.qml").read_text()

        self.assertIn("readonly property var barModuleIds", source)
        self.assertIn("function setBar(left, center, right)", source)
        self.assertIn("return save(next)", source[source.index("function setBar"):])


if __name__ == "__main__":
    unittest.main()
