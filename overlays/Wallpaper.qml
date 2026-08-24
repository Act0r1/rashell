pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: root
    required property string sourcePath

    readonly property string resolvedSource: {
        if (sourcePath.indexOf("~/") === 0) return "file://" + Quickshell.env("HOME") + sourcePath.slice(1)
        if (sourcePath.indexOf("/") === 0) return "file://" + sourcePath
        return sourcePath
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                color: Theme.background
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                WlrLayershell.namespace: "rashell-wallpaper"
                WlrLayershell.layer: WlrLayer.Background

                Image {
                    anchors.fill: parent
                    source: root.resolvedSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }
        }
    }
}
