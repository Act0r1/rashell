import QtQuick

Item {
    id: root

    required property string pluginId
    required property var pluginRegistry

    readonly property string sourceUrl: pluginRegistry.entryPoint(pluginId, "barWidget")

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    Loader {
        id: loader
        anchors.fill: parent
        source: root.sourceUrl

        onLoaded: {
            const plugin = root.pluginRegistry.plugin(root.pluginId)
            if ("manifest" in item) item.manifest = plugin
            if ("pluginRegistry" in item) item.pluginRegistry = root.pluginRegistry
        }

        onStatusChanged: {
            if (status === Loader.Error) console.warn("Rashell plugin failed:", root.pluginId, source)
        }
    }
}
