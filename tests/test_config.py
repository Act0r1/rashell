import json
from pathlib import Path
import unittest

ROOT = Path(__file__).parents[1]
CONFIG_PATH = ROOT / "config.json"
CONFIG_STORE_PATH = ROOT / "core" / "ConfigStore.qml"


class ConfigTest(unittest.TestCase):
    def test_default_config_contract(self) -> None:
        config = json.loads(CONFIG_PATH.read_text())
        self.assertEqual(set(config), {"version", "theme", "wallpaper", "bar"})
        self.assertEqual(config["version"], 1)
        self.assertIn(config["theme"], {"ember", "raven", "jade"})
        self.assertTrue(config["wallpaper"])
        self.assertEqual(set(config["bar"]), {"left", "center", "right"})

        modules = config["bar"]["left"] + config["bar"]["center"] + config["bar"]["right"]
        self.assertEqual(len(modules), len(set(modules)))
        self.assertLessEqual(set(modules), {
            "rashell.workspaces", "rashell.clock", "rashell.audio", "rashell.media",
            "rashell.screenshot", "rashell.keyboard", "rashell.tray", "rashell.notifications",
            "rashell.system", "rashell.tokens", "rashell.control", "rashell.updates",
        })

    def test_legacy_v1_config_is_migrated(self) -> None:
        source = CONFIG_STORE_PATH.read_text()
        self.assertIn('sameKeys(candidate, ["version", "theme", "bar"])', source)
        self.assertIn("candidate.wallpaper = defaults.wallpaper", source)


if __name__ == "__main__":
    unittest.main()
