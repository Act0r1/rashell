import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BluetoothPanelTest(unittest.TestCase):
    def test_bluetooth_module_uses_quickshell_bluez_api(self) -> None:
        state = (ROOT / "modules/system/BluetoothState.qml").read_text()
        panel = (ROOT / "modules/system/BluetoothPanel.qml").read_text()

        self.assertIn("Quickshell.Bluetooth", state)
        self.assertIn("Bluetooth.defaultAdapter", state)
        self.assertIn("device.pair()", state)
        self.assertIn("device.connect()", state)
        self.assertIn("device.disconnect()", state)
        self.assertIn("device.forget()", state)
        self.assertIn("Connected devices", panel)
        self.assertIn("Paired devices", panel)
        self.assertIn("Available devices", panel)
        self.assertIn("setDiscovering", panel)
        self.assertIn('BluetoothState.setEnabled(enable)', panel)
        self.assertIn("Switch {", panel)
        self.assertIn("checked: BluetoothState.enabled", panel)
        self.assertIn('Accessible.name: "Bluetooth power"', panel)

    def test_discovery_stops_after_initial_scan(self) -> None:
        panel = (ROOT / "modules/system/BluetoothPanel.qml").read_text()

        self.assertIn("Component.onCompleted: startDiscovery()", panel)
        self.assertIn("interval: 10000", panel)
        self.assertIn("onTriggered: root.stopDiscovery()", panel)
        self.assertIn("Component.onDestruction: stopDiscovery()", panel)

    def test_discovered_devices_remain_visible_after_scan(self) -> None:
        state = (ROOT / "modules/system/BluetoothState.qml").read_text()
        panel = (ROOT / "modules/system/BluetoothPanel.qml").read_text()

        self.assertIn("rememberedAvailableDevices", state)
        self.assertIn("function rememberAvailableDevices()", state)
        self.assertIn("function mergedAvailableDevices()", state)
        self.assertIn('if (device.remembered) return "Previously discovered"', state)
        self.assertIn('if (deviceRow.device.remembered) return "Find"', panel)

    def test_bluetooth_is_a_configurable_bar_module(self) -> None:
        config_store = (ROOT / "core/ConfigStore.qml").read_text()
        module_slot = (ROOT / "bar/ModuleSlot.qml").read_text()
        editor = (ROOT / "modules/system/BarEditorPanel.qml").read_text()

        self.assertIn('"rashell.bluetooth"', config_store)
        self.assertIn('root.moduleId === "rashell.bluetooth"', module_slot)
        self.assertIn("BluetoothBar", module_slot)
        self.assertIn('"rashell.bluetooth": "Bluetooth"', editor)

    def test_control_center_opens_bluetooth_panel(self) -> None:
        control_panel = (ROOT / "modules/system/ControlPanel.qml").read_text()

        self.assertIn('"/modules/system/BluetoothPanel.qml"', control_panel)
        self.assertIn('accessibleName: "Open Bluetooth devices"', control_panel)
        self.assertNotIn("controlState.toggleBluetooth", control_panel)


if __name__ == "__main__":
    unittest.main()
