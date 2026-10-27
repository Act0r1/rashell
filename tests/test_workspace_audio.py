import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).parents[1]
SPEC = importlib.util.spec_from_file_location("workspace_audio", ROOT / "scripts/workspace-audio.py")
assert SPEC and SPEC.loader
workspace_audio = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workspace_audio)


class WorkspaceAudioTest(unittest.TestCase):
    def test_child_process_resolves_to_nearest_window_owner(self) -> None:
        windows = {100: {3}, 200: {5}}
        parents = {300: 250, 250: 200, 200: 100, 100: 1}

        self.assertEqual(workspace_audio.owner_workspaces(300, windows, parents.get), [5])
        self.assertEqual(workspace_audio.owner_workspaces(100, windows, parents.get), [3])

    def test_unowned_process_and_parent_cycle_return_empty(self) -> None:
        self.assertEqual(workspace_audio.owner_workspaces(10, {}, {10: 11, 11: 10}.get), [])

    def test_shared_process_reports_every_workspace(self) -> None:
        clients = [
            {"pid": 7, "workspace": {"id": 5}},
            {"pid": 7, "workspace": {"id": 3}},
            {"pid": 8, "workspace": {"id": 1}},
        ]

        self.assertEqual(workspace_audio.window_workspaces(clients), {7: {3, 5}, 8: {1}})

    def test_stream_pid_falls_back_to_client_object(self) -> None:
        objects = [
            {"id": 61, "type": "PipeWire:Interface:Client", "info": {"props": {
                "media.class": "Stream/Output/Audio", "application.process.id": 97130}}},
            {"id": 57, "type": "PipeWire:Interface:Node", "info": {"props": {
                "media.class": "Stream/Output/Audio", "client.id": 61}}},
            {"id": 106, "type": "PipeWire:Interface:Node", "info": {"props": {
                "media.class": "Stream/Output/Audio", "application.process.id": "492421", "client.id": 96}}},
            {"id": 70, "type": "PipeWire:Interface:Node", "info": {"props": {
                "media.class": "Stream/Input/Audio", "application.process.id": 5}}},
            {"id": 2, "type": "PipeWire:Interface:Core", "info": None},
        ]

        self.assertEqual(workspace_audio.stream_pids(objects), {57: 97130, 106: 492421})

    def test_parent_pid_handles_parens_in_comm(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            proc = Path(directory)
            (proc / "42").mkdir()
            (proc / "42/stat").write_text("42 (Web (Content) x) S 17 42 42 0 -1\n")

            self.assertEqual(workspace_audio.parent_pid(42, proc), 17)
            self.assertIsNone(workspace_audio.parent_pid(43, proc))


if __name__ == "__main__":
    unittest.main()
