from pathlib import Path
import re
import unittest

THEME_PATH = Path(__file__).parents[1] / "core" / "Theme.qml"


def luminance(color: str) -> float:
    channels = [int(color[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(left: str, right: str) -> float:
    lighter, darker = sorted((luminance(left), luminance(right)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def palettes() -> dict[str, dict[str, str]]:
    source = THEME_PATH.read_text()
    result: dict[str, dict[str, str]] = {}
    for name in ("ember", "raven", "jade"):
        match = re.search(rf"{name}: \{{(.*?)\n        \}}", source, re.DOTALL)
        if match is None:
            raise AssertionError(f"missing {name} palette")
        result[name] = dict(re.findall(r'(\w+): "(#[0-9a-fA-F]{6})"', match.group(1)))
    return result


class ThemeContrastTest(unittest.TestCase):
    def test_functional_contrast(self) -> None:
        for name, palette in palettes().items():
            with self.subTest(theme=name):
                self.assertGreaterEqual(contrast(palette["text"], palette["surface"]), 4.5)
                self.assertGreaterEqual(contrast(palette["textMuted"], palette["surface"]), 4.5)
                self.assertGreaterEqual(contrast(palette["borderInteractive"], palette["surface"]), 3.0)
                self.assertGreaterEqual(contrast(palette["accent"], palette["surface"]), 3.0)


if __name__ == "__main__":
    unittest.main()
