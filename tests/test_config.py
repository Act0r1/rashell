import json
from pathlib import Path
import unittest

ROOT = Path(__file__).parents[1]
CONFIG_PATH = ROOT / "config.json"
CONFIG_STORE_PATH = ROOT / "core" / "ConfigStore.qml"
THEMES_PATH = ROOT / "core" / "themes.json"


class ConfigTest(unittest.TestCase):
    def test_default_config_contract(self) -> None:
        config = json.loads(CONFIG_PATH.read_text())
        theme_ids = {theme["id"] for theme in json.loads(THEMES_PATH.read_text())}
        self.assertEqual(set(config), {"version", "theme", "wallpaper", "captureDirectory", "weatherLocation", "notificationDurationSeconds", "bar"})
        self.assertEqual(config["version"], 1)
        self.assertIn(config["theme"], theme_ids)
        self.assertTrue(config["wallpaper"])
        self.assertEqual(config["captureDirectory"], "~/Pictures/Screenshots")
        self.assertIsInstance(config["weatherLocation"], str)
        self.assertIsInstance(config["notificationDurationSeconds"], int)
        self.assertGreaterEqual(config["notificationDurationSeconds"], 1)
        self.assertLessEqual(config["notificationDurationSeconds"], 60)
        self.assertEqual(set(config["bar"]), {"left", "center", "right"})

        modules = config["bar"]["left"] + config["bar"]["center"] + config["bar"]["right"]
        self.assertEqual(len(modules), len(set(modules)))
        self.assertLessEqual(set(modules), {
            "rashell.workspaces", "rashell.clock", "rashell.weather", "rashell.audio", "rashell.media",
            "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.bluetooth",
            "rashell.notifications", "rashell.system", "rashell.tokens", "rashell.control", "rashell.updates",
        })

    def test_legacy_v1_config_is_migrated(self) -> None:
        source = CONFIG_STORE_PATH.read_text()
        self.assertIn('sameKeys(candidate, ["version", "theme", "bar"])', source)
        self.assertIn('sameKeys(candidate, ["version", "theme", "wallpaper", "bar"])', source)
        self.assertIn('sameKeys(candidate, ["version", "theme", "wallpaper", "captureDirectory", "bar"])', source)
        self.assertIn('sameKeys(candidate, ["version", "theme", "wallpaper", "captureDirectory", "weatherLocation", "bar"])', source)
        self.assertIn("candidate.wallpaper = defaults.wallpaper", source)
        self.assertIn("candidate.captureDirectory = defaults.captureDirectory", source)
        self.assertIn("candidate.weatherLocation = defaults.weatherLocation", source)
        self.assertIn("candidate.notificationDurationSeconds = defaults.notificationDurationSeconds", source)

    def test_save_applies_config_without_waiting_for_file_watcher(self) -> None:
        source = CONFIG_STORE_PATH.read_text()
        save_start = source.index("function save(next)")
        save_end = source.index("function setTheme", save_start)
        save = source[save_start:save_end]

        self.assertIn("applyConfig(next)", save)
        self.assertLess(save.index("applyConfig(next)"), save.index("configFile.setText"))

    def test_theme_validation_uses_catalog(self) -> None:
        source = CONFIG_STORE_PATH.read_text()

        self.assertIn("Theme.names.indexOf(candidate.theme)", source)


if __name__ == "__main__":
    unittest.main()
