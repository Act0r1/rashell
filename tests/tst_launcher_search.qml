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

        const results = LauncherSearch.applications(entries, "x", 40)

        compare(results.length, 2)
        compare(results[0].name, "X")
    }
}
