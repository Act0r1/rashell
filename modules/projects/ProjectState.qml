import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property var projects: projectRecords
    readonly property string error: launchIssue !== "" ? launchIssue : configIssue
    property string configPath: ""
    property var projectRecords: []
    property var projectDefinitions: []
    property string configIssue: ""
    property string launchIssue: ""
    property string pendingProjectName: ""
    property string pendingProjectPayload: ""
    readonly property string helperPath: Quickshell.shellDir + "/scripts/project-launch.py"

    signal failed(string message)
    signal launched(string name)

    function isPlainObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value)
    }

    function validateProject(project, index, seenIds) {
        if (!isPlainObject(project)) return "project " + (index + 1) + " must be an object"

        const allowed = ["id", "name", "path", "commands", "url", "comment", "icon"]
        const keys = Object.keys(project)
        for (let keyIndex = 0; keyIndex < keys.length; keyIndex++) {
            if (allowed.indexOf(keys[keyIndex]) === -1) return "unknown project field: " + keys[keyIndex]
        }

        if (typeof project.id !== "string" || project.id.trim() === "") return "project " + (index + 1) + " has an invalid id"
        if (seenIds.indexOf(project.id) !== -1) return "duplicate project id: " + project.id
        seenIds.push(project.id)

        if (typeof project.name !== "string" || project.name.trim() === "") return "project " + project.id + " has an invalid name"
        if (typeof project.path !== "string" || project.path.charAt(0) !== "/") return "project " + project.id + " path must be absolute"
        if (!Array.isArray(project.commands)) return "project " + project.id + " commands must be an array"

        for (let commandIndex = 0; commandIndex < project.commands.length; commandIndex++) {
            const command = project.commands[commandIndex]
            if (!Array.isArray(command) || command.length === 0) return "project " + project.id + " command " + (commandIndex + 1) + " must be a nonempty argv array"
            for (let argumentIndex = 0; argumentIndex < command.length; argumentIndex++) {
                if (typeof command[argumentIndex] !== "string") return "project " + project.id + " command arguments must be strings"
            }
            if (command[0].trim() === "") return "project " + project.id + " command executable cannot be empty"
        }

        if (project.url !== undefined) {
            if (typeof project.url !== "string" || !/^https?:\/\/[^\s/?#]+(?:[/?#][^\s]*)?$/.test(project.url)) return "project " + project.id + " URL must use http or https"
        }
        if (project.comment !== undefined && typeof project.comment !== "string") return "project " + project.id + " comment must be a string"
        if (project.icon !== undefined && typeof project.icon !== "string") return "project " + project.id + " icon must be a string"
        if (project.commands.length === 0 && project.url === undefined) return "project " + project.id + " must have a command or URL"
        return ""
    }

    function applyText(text) {
        try {
            const document = JSON.parse(String(text || ""))
            if (!isPlainObject(document)) throw new Error("top level must be an object")
            const keys = Object.keys(document)
            if (keys.length !== 2 || keys.indexOf("version") === -1 || keys.indexOf("projects") === -1) throw new Error("top level must contain only version and projects")
            if (document.version !== 1) throw new Error("unsupported config version")
            if (!Array.isArray(document.projects)) throw new Error("projects must be an array")

            const seenIds = []
            const records = []
            const definitions = []
            for (let index = 0; index < document.projects.length; index++) {
                const project = document.projects[index]
                const issue = validateProject(project, index, seenIds)
                if (issue !== "") throw new Error(issue)

                const normalized = {
                    id: project.id,
                    name: project.name,
                    path: project.path,
                    comment: project.comment === undefined ? "" : project.comment,
                    icon: project.icon === undefined ? "" : project.icon,
                    commands: project.commands.map(function(command) { return Array.from(command) })
                }
                if (project.url !== undefined) normalized.url = project.url
                definitions.push(normalized)
                records.push({
                    id: normalized.id,
                    name: normalized.name,
                    path: normalized.path,
                    comment: normalized.comment,
                    icon: normalized.icon
                })
            }

            projectDefinitions = definitions
            projectRecords = records
            configIssue = ""
        } catch (error) {
            configIssue = "Project config rejected at " + configPath + ": " + error
        }
    }

    function launch(projectId: string): bool {
        launchIssue = ""
        if (launchProcess.running) {
            launchIssue = "A project is already launching"
            failed(launchIssue)
            return false
        }

        let project = null
        for (let index = 0; index < projectDefinitions.length; index++) {
            if (projectDefinitions[index].id === projectId) {
                project = projectDefinitions[index]
                break
            }
        }
        if (project === null) {
            launchIssue = "Unknown project: " + projectId
            failed(launchIssue)
            return false
        }

        pendingProjectName = project.name
        pendingProjectPayload = JSON.stringify(project)
        launchProcess.exec({ command: [helperPath] })
        return true
    }

    function initialize() {
        const explicitPath = String(Quickshell.env("RASHELL_PROJECTS_CONFIG") || "")
        if (explicitPath !== "") {
            configPath = explicitPath
            if (explicitPath.charAt(0) !== "/") {
                configIssue = "RASHELL_PROJECTS_CONFIG must be an absolute path"
                return
            }
            configFile.path = explicitPath
            return
        }

        const home = String(Quickshell.env("HOME") || "")
        const configHome = String(Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config"))
        configPath = configHome + "/rashell/projects.json"
        configFile.path = configPath
    }

    FileView {
        id: configFile
        path: ""
        watchChanges: true
        printErrors: false

        onLoaded: root.applyText(text())
        onFileChanged: reload()
        onLoadFailed: function(fileError) {
            if (fileError === FileViewError.FileNotFound) {
                root.projectDefinitions = []
                root.projectRecords = []
                root.configIssue = ""
                return
            }
            root.configIssue = "Project config unavailable at " + root.configPath + ": " + FileViewError.toString(fileError)
        }
    }

    Process {
        id: launchProcess
        stdinEnabled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onStarted: write(root.pendingProjectPayload + "\n")

        onExited: function(exitCode) {
            const projectName = root.pendingProjectName
            root.pendingProjectName = ""
            root.pendingProjectPayload = ""
            if (exitCode === 0) {
                root.launchIssue = ""
                root.launched(projectName)
                return
            }

            const message = String(launchProcess.stderr.text || "").trim()
            root.launchIssue = message !== "" ? message : "Could not launch " + projectName
            root.failed(root.launchIssue)
        }
    }

    Component.onCompleted: initialize()
}
