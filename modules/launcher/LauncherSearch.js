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

function applications(entries, query, limit) {
    const normalizedQuery = String(query || "").trim().toLowerCase()
    const matches = entries.filter(function(entry) {
        return entry && !entry.noDisplay && !entry.hidden
            && (normalizedQuery === "" || matchScore(entry, normalizedQuery) !== -1)
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

function records(entries, query, limit) {
    return filtered(entries, query, limit)
}
