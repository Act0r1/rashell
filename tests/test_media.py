import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class MediaPositionTest(unittest.TestCase):
    def test_panel_refreshes_playing_position_unless_dragging(self) -> None:
        source = (ROOT / "modules/media/MediaPanel.qml").read_text()

        self.assertRegex(source, r"\bTimer\s*\{")
        self.assertRegex(
            source,
            r"\brunning:\s*root\.mediaState\.playing\s*&&\s*!progress\.pressed\b",
        )
        self.assertRegex(source, r"\brepeat:\s*true\b")
        self.assertRegex(source, r"\binterval:\s*1000\b")
        self.assertRegex(
            source,
            r"root\.mediaState\.player\.positionChanged\(\)",
        )

    def test_seek_is_sent_once_when_dragging_ends(self) -> None:
        source = (ROOT / "modules/media/MediaPanel.qml").read_text()

        self.assertRegex(
            source,
            r"onPressedChanged:\s*\{\s*if\s*\(!pressed\)\s*"
            r"root\.mediaState\.seek\(value\s*/\s*to\)\s*\}",
        )
        self.assertIsNone(
            re.search(r"onMoved:\s*root\.mediaState\.seek", source),
        )


if __name__ == "__main__":
    unittest.main()
