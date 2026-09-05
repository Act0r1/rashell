import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class AudioControlsTest(unittest.TestCase):
    def test_level_slider_has_a_pointer_hit_area(self) -> None:
        source = (ROOT / "ui/LevelSlider.qml").read_text()

        self.assertRegex(source, r"implicitHeight:\s*Theme\.controlHeight")

    def test_default_level_scale_ends_at_one_hundred_percent(self) -> None:
        slider_source = (ROOT / "ui/LevelSlider.qml").read_text()
        audio_source = (ROOT / "modules/audio/AudioState.qml").read_text()
        osd_source = (ROOT / "overlays/VolumeOsd.qml").read_text()

        self.assertRegex(slider_source, r"\bto:\s*1\b")
        self.assertRegex(
            audio_source,
            r"Math\.min\(1,\s*Number\(value\)\)",
        )
        self.assertIsNone(re.search(r"\bto:\s*1\.5\b", slider_source))
        self.assertIsNone(re.search(r"outputVolume\s*/\s*1\.5", osd_source))

    def test_osd_observes_external_output_volume_and_mute_changes(self) -> None:
        audio_source = (ROOT / "modules/audio/AudioState.qml").read_text()
        shell_source = (ROOT / "shell.qml").read_text()

        self.assertRegex(
            audio_source,
            r"function\s+onVolumesChanged\(\)\s*\{\s*state\.observeOutputVolumeChange\(\)",
        )
        self.assertRegex(
            audio_source,
            r"function\s+onMutedChanged\(\)\s*\{\s*state\.observeOutputMuteChange\(\)",
        )
        self.assertRegex(
            shell_source,
            r"function\s+onOutputChangeObserved\(outputName\)",
        )
        self.assertRegex(
            shell_source,
            r"outputName\s*!==\s*\"\"\s*\?\s*outputName\s*:\s*panelCoordinator\.preferredOutputName\(\)",
        )


if __name__ == "__main__":
    unittest.main()
