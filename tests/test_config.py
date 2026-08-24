import json
from pathlib import Path
import unittest

CONFIG_PATH = Path(__file__).parents[1] / "config.json"


class ConfigTest(unittest.TestCase):
    def test_default_config_contract(self) -> None:
        config = json.loads(CONFIG_PATH.read_text())
        self.assertEqual(set(config), {"version", "theme", "bar"})
        self.assertEqual(config["version"], 1)
        self.assertIn(config["theme"], {"ember", "raven", "jade"})
        self.assertEqual(set(config["bar"]), {"left", "center", "right"})

        modules = config["bar"]["left"] + config["bar"]["center"] + config["bar"]["right"]
        self.assertEqual(len(modules), len(set(modules)))
        self.assertLessEqual(set(modules), {"rashell.workspaces", "rashell.clock", "rashell.audio"})


if __name__ == "__main__":
    unittest.main()
