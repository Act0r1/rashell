pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

Scope {
    id: root

    required property var configStore

    readonly property string directory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property alias model: files
    readonly property int count: files.count
    readonly property bool ready: files.status === FolderListModel.Ready

    function pathAt(index) {
        if (index < 0 || index >= files.count) return ""
        return String(files.get(index, "filePath"))
    }

    function nameAt(index) {
        if (index < 0 || index >= files.count) return ""
        const fileName = String(files.get(index, "fileName"))
        const dot = fileName.lastIndexOf(".")
        return dot > 0 ? fileName.slice(0, dot) : fileName
    }

    function sizeLabelAt(index) {
        if (index < 0 || index >= files.count) return ""
        const bytes = Number(files.get(index, "fileSize"))
        if (!isFinite(bytes) || bytes <= 0) return ""
        if (bytes < 1024 * 1024) return Math.round(bytes / 1024) + " KB"
        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
    }

    function indexOfCurrent() {
        const current = configStore.wallpaperPath
        for (let index = 0; index < files.count; index++) {
            if (pathAt(index) === current) return index
        }
        return 0
    }

    function apply(index) {
        const path = pathAt(index)
        if (path === "") return false
        return configStore.setWallpaper(path)
    }

    FolderListModel {
        id: files
        folder: "file://" + root.directory
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }
}
