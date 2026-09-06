import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.modules.download

ShellRoot {
    MediaDownloadState { id: state }
    QtObject {
        id: coordinator
        property Item anchorItem: null
        function close(reason: string): void { panel.visible = false }
    }
    PanelWindow {
        id: panel
        visible: true
        anchors { top: true; right: true }
        margins { top: 44; right: 60 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        color: "transparent"
        MediaDownloadPanel {
            id: content
            width: parent.width
            downloadState: state
            coordinator: coordinator
        }
    }
    IpcHandler {
        target: "check"
        function start(url: string): void { state.url = url; state.start() }
        function copy(): void { state.copySaved() }
        function cancel(): void { state.cancel() }
        function snapshot(): string {
            return JSON.stringify({available: state.available, busy: state.busy, status: state.status, error: state.error, copied: state.copied, savedPath: state.savedPath, title: state.title, kind: state.savedKind, progress: state.progress})
        }
    }
    Component.onCompleted: Theme.activeName = "raven"
}
