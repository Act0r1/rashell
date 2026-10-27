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

    function test_exact_alias_ranks_first() {
        const entries = [
            { id: "fr-tool", name: "Fr", comment: "", keywords: "" },
            { id: "firefox", name: "Firefox", comment: "", keywords: "" }
        ]
        const prefs = { favorites: [], aliases: { firefox: "frf" } }

        compare(LauncherSearch.applications(entries, "FRF", prefs)[0].id, "firefox")
        compare(LauncherSearch.applications(entries, "fr", prefs).map(function(entry) { return entry.id }), ["fr-tool"])
        compare(LauncherSearch.applications(entries, "fr", { favorites: [], aliases: { firefox: "fr" } })[0].id, "firefox")
    }

    function test_alias_finds_app_without_name_match() {
        const entries = [{ id: "org.gnome.Nautilus", name: "Files", comment: "", keywords: "" }]
        const items = LauncherSearch.applicationItems(entries, "naut2", { favorites: [], aliases: { "org.gnome.Nautilus": "naut2" } })

        compare(items.length, 1)
        compare(items[0].alias, "naut2")
    }

    function test_favorites_first_on_empty_query() {
        const entries = [
            { id: "alpha", name: "Alpha", comment: "", keywords: "" },
            { id: "zed", name: "Zed", comment: "", keywords: "" }
        ]
        const items = LauncherSearch.applicationItems(entries, "", { favorites: ["zed"], aliases: {} })

        compare(items[0].id, "zed")
        compare(items[0].favorite, true)
        compare(items[1].favorite, false)
    }

    function test_favorite_only_breaks_ties_while_searching() {
        const entries = [
            { id: "code", name: "Code", comment: "", keywords: "" },
            { id: "cool", name: "Cool", comment: "", keywords: "" },
            { id: "notes", name: "Notes", comment: "co-op notes", keywords: "" }
        ]
        const results = LauncherSearch.applications(entries, "co", { favorites: ["cool", "notes"], aliases: {} })

        compare(results.map(function(entry) { return entry.id }), ["cool", "code", "notes"])
    }

    function test_destructive_action_detection() {
        compare(LauncherSearch.isDestructiveAction({ id: "AppImageLauncher-Remove-AppImage", name: "Delete this AppImage" }), true)
        compare(LauncherSearch.isDestructiveAction({ id: "new-window", name: "New Window" }), false)
    }

    function test_gear_lever_appimage_gets_remove_action() {
        const entry = {
            name: "Handy",
            actions: [],
            command: ["env", "DESKTOPINTEGRATION=1", "/home/user/AppImages/handy.appimage", "--flag"]
        }

        compare(LauncherSearch.deleteAction(entry).command,
            ["flatpak", "run", "it.mijorus.gearlever", "--remove", "-y", "/home/user/AppImages/handy.appimage"])
    }

    function test_regular_app_has_no_remove_action() {
        compare(LauncherSearch.deleteAction({ name: "Firefox", actions: [], command: ["/usr/bin/firefox"] }), null)
        compare(LauncherSearch.deleteAction({ name: "Craft", actions: [], command: ["/home/user/Applications/pdfcraft.AppImage"] }), null)
    }
}
