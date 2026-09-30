from pathlib import Path
import json
import unittest

THEME_PATH = Path(__file__).parents[1] / "core" / "themes.json"
PALETTE_KEYS = {
    "background", "surface", "surfaceRaised", "accent", "accentMuted", "text", "textMuted",
    "textDisabled", "textOnAccent", "border", "borderInteractive", "danger", "textOnDanger",
    "accentSecondary", "dangerText", "borderControl", "success", "warning", "info",
}
TEXT_ROLES = ("accentSecondary", "dangerText", "success", "warning", "info")
SYNTAX_ROLES = {
    "comment", "string", "keyword", "function", "type", "number",
    "constant", "variable", "operator", "punctuation",
}
TERMINAL_SETTING_KEYS = {
    "background", "foreground", "cursor-color", "cursor-text", "selection-background",
    "selection-foreground", "split-divider-color", "unfocused-split-fill",
    "search-background", "search-foreground", "search-selected-background",
    "search-selected-foreground",
}
BASE16_KEYS = {f"base{index:02X}" for index in range(16)}


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

        self.assertEqual(len(themes), 6)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(ids, [
            "raven", "dusk", "tokyonight", "tokyostorm", "ayu-dark", "ayu-mirage",
        ])
        for theme in themes:
            with self.subTest(theme=theme["id"]):
                self.assertEqual(set(theme), {"id", "name", "description", "kind", "palette", "syntax", "terminal"})
                self.assertIn(theme["kind"], {"dark", "light"})
                self.assertEqual(set(theme["palette"]), PALETTE_KEYS)
                self.assertEqual(set(theme["syntax"]), SYNTAX_ROLES)
                terminal = theme["terminal"]
                self.assertEqual(set(terminal), {"base16", "ansi", "settings"})
                self.assertEqual(set(terminal["base16"]), BASE16_KEYS)
                self.assertEqual(len(terminal["ansi"]), 16)
                self.assertEqual(set(terminal["settings"]), TERMINAL_SETTING_KEYS)
                for color in list(theme["palette"].values()) + list(theme["syntax"].values()) \
                        + list(terminal["base16"].values()) + list(terminal["ansi"]) \
                        + list(terminal["settings"].values()):
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
                for role in TEXT_ROLES:
                    self.assertGreaterEqual(contrast(palette[role], palette["surface"]), 4.5, role)
                    self.assertGreaterEqual(contrast(palette[role], palette["surfaceRaised"]), 4.5, role)
                self.assertGreaterEqual(contrast(palette["borderControl"], palette["surface"]), 3.0)
                self.assertGreaterEqual(contrast(palette["borderControl"], palette["surfaceRaised"]), 3.0)
                self.assertGreaterEqual(contrast(palette["dangerText"], palette["surface"]), 4.5)
                self.assertGreaterEqual(contrast(palette["dangerText"], palette["surfaceRaised"]), 4.5)

    def test_terminal_contract(self) -> None:
        for theme in catalog():
            terminal = theme["terminal"]
            background = terminal["settings"]["background"]
            with self.subTest(theme=theme["id"]):
                self.assertEqual(len(terminal["ansi"]), 16)
                for role, color in theme["syntax"].items():
                    self.assertGreaterEqual(contrast(color, background), 4.5, role)
                self.assertNotEqual(terminal["base16"]["base0D"], terminal["base16"]["base0E"])
                self.assertNotEqual(terminal["ansi"][4], terminal["ansi"][5])
                self.assertNotEqual(terminal["ansi"][4], terminal["base16"]["base0E"])
                self.assertNotEqual(terminal["ansi"][5], terminal["base16"]["base0D"])


if __name__ == "__main__":
    unittest.main()
