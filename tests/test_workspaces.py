import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_STATE_PATH = ROOT / "modules/workspaces/WorkspaceState.qml"


class WorkspaceStateTest(unittest.TestCase):
    def test_visible_ids_include_hyprland_workspaces_beyond_defaults(self) -> None:
        source = WORKSPACE_STATE_PATH.read_text()

        self.assertIn("readonly property var baseIds: [1, 2, 3, 4, 5, 6]", source)
        self.assertIn("readonly property var ids: visibleWorkspaceIds()", source)
        self.assertIn("function visibleWorkspaceIds()", source)
        self.assertIn("const workspaceId = Number(workspaces[index].id)", source)
        self.assertIn("result.sort((left, right) => left - right)", source)
        self.assertNotIn("readonly property var ids: [1, 2, 3, 4, 5, 6]", source)


if __name__ == "__main__":
    unittest.main()
