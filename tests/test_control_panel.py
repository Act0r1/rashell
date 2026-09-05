import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ControlPanelTest(unittest.TestCase):
    def test_audio_device_selection_switches_panels_atomically(self) -> None:
        source = (ROOT / "modules/system/ControlPanel.qml").read_text()
        handler_start = source.index("function openAudioDevices()")
        handler_end = source.index("\n    function ", handler_start + 1)
        handler = source[handler_start:handler_end]

        self.assertIn("onClicked: root.openAudioDevices()", source)
        self.assertRegex(handler, r'coordinator.open\(\s*"audio"')
        self.assertNotIn("coordinator.close", handler)
        self.assertNotIn("Qt.callLater", handler)


if __name__ == "__main__":
    unittest.main()
