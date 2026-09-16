import QtQuick
import QtTest
import "../modules/launcher/LauncherSearch.js" as LauncherSearch

TestCase {
    name: "LauncherSearch"

    function test_exact_name_ranks_before_metadata_match() {
        const entries = [
            { name: "Console", comment: "", keywords: "command;terminal;kgx;kings cross;" },
            { name: "X", comment: "", keywords: "" }
        ]

        const results = LauncherSearch.applications(entries, "x")

        compare(results.length, 2)
        compare(results[0].name, "X")
    }

    function test_applications_are_not_limited() {
        const entries = []
        for (let index = 0; index < 41; index++) {
            entries.push({ name: "App " + index, comment: "", keywords: "" })
        }

        compare(LauncherSearch.applicationItems(entries, "").length, 41)
    }

    function test_empty_query_omits_desktop_actions() {
        const entries = [
            {
                name: "MonoCode",
                comment: "one UI",
                keywords: "",
                icon: "monocode",
                actions: [
                    { id: "AppImageLauncher-Remove-AppImage", name: "Delete this AppImage", icon: "AppImageLauncher" }
                ]
            }
        ]

        const results = LauncherSearch.applicationItems(entries, "")

        compare(results.length, 1)
        compare(results[0].kind, "app")
        compare(results[0].name, "MonoCode")
    }

    function test_app_query_keeps_a_single_app_row() {
        const entries = [
            {
                name: "MonoCode",
                comment: "one UI",
                keywords: "",
                icon: "monocode",
                actions: [
                    { id: "AppImageLauncher-Remove-AppImage", name: "Delete this AppImage", icon: "AppImageLauncher" }
                ]
            },
            { name: "Firefox", comment: "", keywords: "", icon: "firefox", actions: [] }
        ]

        const results = LauncherSearch.applicationItems(entries, "mono")

        compare(results.length, 1)
        compare(results[0].kind, "app")
        compare(results[0].name, "MonoCode")
        compare(LauncherSearch.deleteAction(results[0].entry).id, "AppImageLauncher-Remove-AppImage")
    }

    function test_action_query_finds_the_app_not_a_second_row() {
        const entries = [
            {
                name: "MonoCode",
                comment: "one UI",
                keywords: "",
                icon: "monocode",
                actions: [
                    { id: "AppImageLauncher-Remove-AppImage", name: "Delete this AppImage", icon: "AppImageLauncher" }
                ]
            }
        ]

        const results = LauncherSearch.applicationItems(entries, "delete")

        compare(results.length, 1)
        compare(results[0].kind, "app")
        compare(results[0].name, "MonoCode")
        compare(LauncherSearch.deleteAction(results[0].entry).name, "Delete this AppImage")
    }

    function test_hidden_apps_do_not_expose_actions() {
        const entries = [
            {
                name: "HiddenApp",
                comment: "",
                keywords: "",
                hidden: true,
                actions: [{ id: "remove", name: "Delete this AppImage" }]
            }
        ]

        const results = LauncherSearch.applicationItems(entries, "delete")

        compare(results.length, 0)
    }

    function test_destructive_action_detection() {
        compare(LauncherSearch.isDestructiveAction({ id: "AppImageLauncher-Remove-AppImage", name: "Delete this AppImage" }), true)
        compare(LauncherSearch.isDestructiveAction({ id: "new-window", name: "New Window" }), false)
    }
}
