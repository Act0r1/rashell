from pathlib import Path
import json
import unittest

THEME_PATH = Path(__file__).parents[1] / "core" / "themes.json"
PALETTE_KEYS = {
    "background", "surface", "surfaceRaised", "accent", "accentMuted", "text", "textMuted",
    "textDisabled", "textOnAccent", "border", "borderInteractive", "danger", "textOnDanger",
}


def luminance(color: str) -> float:
    channels = [int(color[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(left: str, right: str) -> float:
    lighter, darker = sorted((luminance(left), luminance(right)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def catalog() -> list[dict[str, object]]:
    return json.loads(THEME_PATH.read_text())


class ThemeContrastTest(unittest.TestCase):
    def test_catalog_contract(self) -> None:
        themes = catalog()
        ids = [theme["id"] for theme in themes]

        self.assertEqual(len(themes), 17)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(ids, [
            "oilslick", "muninn", "nevermore", "talon", "ember", "raven", "jade",
            "tide", "frost", "paper", "dune", "dusk", "tokyonight", "tokyostorm",
            "ayu-dark", "ayu-mirage", "ayu-light",
        ])
        for theme in themes:
            with self.subTest(theme=theme["id"]):
                self.assertEqual(set(theme), {"id", "name", "description", "kind", "palette"})
                self.assertIn(theme["kind"], {"dark", "light"})
                self.assertEqual(set(theme["palette"]), PALETTE_KEYS)
                for color in theme["palette"].values():
                    self.assertRegex(color, r"^#[0-9a-fA-F]{6}$")

    def test_functional_contrast(self) -> None:
        for theme in catalog():
            palette = theme["palette"]
            with self.subTest(theme=theme["id"]):
                self.assertGreaterEqual(contrast(palette["text"], palette["surface"]), 4.5)
                self.assertGreaterEqual(contrast(palette["textMuted"], palette["surface"]), 4.5)
                self.assertGreaterEqual(contrast(palette["borderInteractive"], palette["surface"]), 3.0)
                self.assertGreaterEqual(contrast(palette["accent"], palette["surface"]), 3.0)
                self.assertGreaterEqual(contrast(palette["textOnAccent"], palette["accent"]), 4.5)
                self.assertGreaterEqual(contrast(palette["textOnDanger"], palette["danger"]), 4.5)


if __name__ == "__main__":
    unittest.main()
