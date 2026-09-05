import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class SystemMonitorTest(unittest.TestCase):
    def test_state_collects_all_monitor_data(self) -> None:
        source = (ROOT / "modules/system/SystemState.qml").read_text()

        self.assertIn("property var cpuHistory", source)
        self.assertIn("property real temperatureCelsius", source)
        self.assertIn("property real uptimeSeconds", source)
        self.assertIn("readonly property alias topProcesses", source)
        self.assertIn("/proc/uptime", source)
        self.assertIn("/sys/class/hwmon/hwmon*/temp*_input", source)
        self.assertIn("ps -eo pid=,ppid=,pcpu=,rss=,comm=", source)
        self.assertIn("state.cpuHistory.slice(-29)", source)

    def test_monitor_excludes_its_collector_processes_before_limiting(self) -> None:
        source = (ROOT / "modules/system/SystemState.qml").read_text()

        self.assertIn("awk -v collector=$$", source)
        self.assertIn("$1 != collector && $2 != collector", source)
        self.assertIn("if (++count == 5) exit", source)
        self.assertNotIn("head -n 5", source)

    def test_process_signals_are_validated_and_exposed(self) -> None:
        state_source = (ROOT / "modules/system/SystemState.qml").read_text()
        panel_source = (ROOT / "modules/system/SystemPanel.qml").read_text()

        self.assertIn('["TERM", "KILL", "STOP", "CONT", "HUP"]', state_source)
        self.assertIn('Quickshell.execDetached(["kill", "-s", signalName, String(pid)])', state_source)
        self.assertIn('text: "SIGNAL"', panel_source)
        self.assertIn('model: ["TERM", "KILL", "STOP", "CONT", "HUP"]', panel_source)
        self.assertIn("root.sendSelectedSignal(modelData)", panel_source)

    def test_panel_exposes_monitor_details(self) -> None:
        source = (ROOT / "modules/system/SystemPanel.qml").read_text()

        self.assertIn('label: "CPU"', source)
        self.assertIn('label: "MEMORY"', source)
        self.assertIn('label: "TEMPERATURE"', source)
        self.assertIn('label: "DISK"', source)
        self.assertIn("root.systemState.cpuHistory", source)
        self.assertIn("root.systemState.formatUptime", source)
        self.assertIn("root.systemState.topProcesses", source)
        self.assertIn("Canvas {", source)
        self.assertEqual(source.count("parent.width - 240 - Theme.spaceMd"), 2)


if __name__ == "__main__":
    unittest.main()
