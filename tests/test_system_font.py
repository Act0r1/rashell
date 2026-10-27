import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

ROOT = Path(__file__).parents[1]
SCRIPT = ROOT / "scripts/system-font.py"


class SystemFontTest(unittest.TestCase):
    def test_sync_swaps_family_and_keeps_sizes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / "config"
            bin_dir = Path(directory) / "bin"
            log = Path(directory) / "gsettings.log"
            bin_dir.mkdir()
            gsettings = bin_dir / "gsettings"
            gsettings.write_text(textwrap.dedent(f"""\
                #!/bin/sh
                if [ "$1" = get ]; then echo "'Roboto Flex 11'"; else echo "$@" >> {log}; fi
            """))
            gsettings.chmod(0o755)
            files = {
                "gtk-3.0/settings.ini": "[Settings]\ngtk-theme-name=adw\ngtk-font-name=Roboto Flex 11\n",
                "qt6ct/qt6ct.conf": '[Fonts]\nfixed="JetBrains Mono,11,-1"\ngeneral="Roboto Flex,11,-1,5"\n',
                "kdeglobals": "[General]\nfixed=JetBrains Mono,11\nfont=Roboto Flex,11,-1\n[Other]\nfont=Keep,1\n",
            }
            for name, content in files.items():
                (home / name).parent.mkdir(parents=True, exist_ok=True)
                (home / name).write_text(content)

            subprocess.run(
                ["python3", "-I", str(SCRIPT), "--family", "Libron", "--fallback", "Noto Serif",
                 "--config-home", str(home)],
                check=True, env={**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}"},
            )

            self.assertEqual(log.read_text().splitlines(), [
                "set org.gnome.desktop.interface font-name Libron 11",
                "set org.gnome.desktop.interface document-font-name Libron 11",
            ])
            self.assertIn("gtk-font-name=Libron 11\n", (home / "gtk-3.0/settings.ini").read_text())
            qt = (home / "qt6ct/qt6ct.conf").read_text()
            self.assertIn('general="Libron,11,-1,5"', qt)
            self.assertIn('fixed="JetBrains Mono,11,-1"', qt)
            kde = (home / "kdeglobals").read_text()
            self.assertIn("font=Libron,11,-1\n", kde)
            self.assertIn("fixed=JetBrains Mono,11\n", kde)
            self.assertIn("font=Keep,1\n", kde)
            fontconfig = (home / "fontconfig/conf.d/50-rashell-font.conf").read_text()
            self.assertIn("<prefer><family>Libron</family></prefer>", fontconfig)
            self.assertIn("<accept><family>Noto Serif</family></accept>", fontconfig)


if __name__ == "__main__":
    unittest.main()
