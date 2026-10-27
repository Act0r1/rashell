.pragma library

function matchScore(entry, query) {
    const name = String(entry.name || "").toLowerCase()
    const comment = String(entry.comment || "").toLowerCase()
    const keywords = String(entry.keywords || "").toLowerCase()
    const path = String(entry.path || "").toLowerCase()

    if (name === query) return 0
    if (name.indexOf(query) === 0) return 1
    if (name.split(/[\s._-]+/).some(function(word) { return word.indexOf(query) === 0 })) return 2
    if (name.indexOf(query) !== -1) return 3

    const keywordItems = keywords.split(/[;,\s]+/).filter(function(keyword) { return keyword.length > 0 })
    if (keywordItems.indexOf(query) !== -1) return 4
    if (keywordItems.some(function(keyword) { return keyword.indexOf(query) === 0 })) return 5
    if (comment.indexOf(query) !== -1) return 6
    if (keywords.indexOf(query) !== -1) return 7
    if (path.indexOf(query) !== -1) return 8
    return -1
}

function filtered(entries, query, limit) {
    const normalizedQuery = String(query || "").trim().toLowerCase()
    const source = Array.isArray(entries) ? entries : []
    const matches = source.filter(function(entry) {
        return entry && (normalizedQuery === "" || matchScore(entry, normalizedQuery) !== -1)
    })

    matches.sort(function(left, right) {
        if (normalizedQuery !== "") {
            const scoreDifference = matchScore(left, normalizedQuery) - matchScore(right, normalizedQuery)
            if (scoreDifference !== 0) return scoreDifference
        }
        return String(left.name || "").localeCompare(String(right.name || ""))
    })

    return matches.slice(0, limit)
}

function isFavorite(entry, prefs) {
    const favorites = prefs && Array.isArray(prefs.favorites) ? prefs.favorites : []
    return !!entry && favorites.indexOf(String(entry.id || "")) !== -1
}

function aliasOf(entry, prefs) {
    const aliases = prefs && prefs.aliases ? prefs.aliases : {}
    const alias = entry ? aliases[String(entry.id || "")] : undefined
    return typeof alias === "string" ? alias : ""
}

function appScore(entry, query, prefs) {
    if (query !== "" && aliasOf(entry, prefs) === query) return 0
    const score = matchScore(entry, query)
    return score === -1 ? -1 : score + 1
}

function applications(entries, query, prefs) {
    const normalizedQuery = String(query || "").trim().toLowerCase()
    const matches = entries.filter(function(entry) {
        return entry && !entry.noDisplay && !entry.hidden
            && (normalizedQuery === "" || appScore(entry, normalizedQuery, prefs) !== -1)
    })

    matches.sort(function(left, right) {
        if (normalizedQuery !== "") {
            const scoreDifference = appScore(left, normalizedQuery, prefs) - appScore(right, normalizedQuery, prefs)
            if (scoreDifference !== 0) return scoreDifference
        }
        const favoriteDifference = Number(isFavorite(right, prefs)) - Number(isFavorite(left, prefs))
        if (favoriteDifference !== 0) return favoriteDifference
        return String(left.name || "").localeCompare(String(right.name || ""))
    })

    return matches
}

function actionRecords(entry) {
    const actions = entry && entry.actions
    if (!actions || actions.length === 0) return []
    const records = []
    for (let index = 0; index < actions.length; index++) {
        const action = actions[index]
        if (!action || String(action.name || "").length === 0) continue
        records.push(action)
    }
    return records
}

function isDestructiveAction(action) {
    const id = String(action && action.id || "").toLowerCase()
    const name = String(action && action.name || "").toLowerCase()
    return id.indexOf("remove") !== -1 || id.indexOf("delete") !== -1 || id.indexOf("uninstall") !== -1
        || name.indexOf("delete") !== -1 || name.indexOf("remove") !== -1 || name.indexOf("uninstall") !== -1
}

function gearLeverAppImage(entry) {
    const command = entry && entry.command
    if (!command || command.length === 0) return ""
    for (let index = 0; index < command.length; index++) {
        const part = String(command[index] || "")
        if (/\/AppImages\/[^/]+\.appimage$/i.test(part)) return part
    }
    return ""
}

function deleteAction(entry) {
    const actions = actionRecords(entry)
    for (let index = 0; index < actions.length; index++) {
        if (isDestructiveAction(actions[index])) return actions[index]
    }
    const appImage = gearLeverAppImage(entry)
    if (appImage === "") return null
    return {
        id: "gearlever-remove",
        name: "Remove AppImage",
        command: ["flatpak", "run", "it.mijorus.gearlever", "--remove", "-y", appImage]
    }
}

function actionMatches(action, entry, query) {
    if (!action || query === "") return false
    return matchScore({
        name: action.name,
        comment: entry && entry.name || "",
        keywords: "",
        path: ""
    }, query) !== -1
}

function applicationItems(entries, query, prefs) {
    const normalizedQuery = String(query || "").trim().toLowerCase()
    const apps = applications(entries, query, prefs)
    const items = []
    const seen = []

    function pushApp(entry) {
        if (!entry || seen.indexOf(entry) !== -1) return
        seen.push(entry)
        items.push({
            kind: "app",
            entry: entry,
            id: String(entry.id || ""),
            favorite: isFavorite(entry, prefs),
            alias: aliasOf(entry, prefs),
            name: entry.name,
            comment: entry.comment || "",
            icon: entry.icon,
            enabled: true
        })
    }

    for (let index = 0; index < apps.length; index++) pushApp(apps[index])
    if (normalizedQuery === "") return items

    const extras = []
    const source = entries && entries.filter ? entries : []
    for (let index = 0; index < source.length; index++) {
        const entry = source[index]
        if (!entry || entry.noDisplay || entry.hidden) continue
        if (seen.indexOf(entry) !== -1) continue
        const actions = actionRecords(entry)
        for (let actionIndex = 0; actionIndex < actions.length; actionIndex++) {
            if (actionMatches(actions[actionIndex], entry, normalizedQuery)) {
                extras.push(entry)
                break
            }
        }
    }

    extras.sort(function(left, right) {
        return String(left.name || "").localeCompare(String(right.name || ""))
    })
    for (let index = 0; index < extras.length; index++) pushApp(extras[index])
    return items
}

function records(entries, query, limit) {
    return filtered(entries, query, limit)
}
