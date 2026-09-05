import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    property string password: ""
    property string message: "Enter your password to unlock"
    property bool failed: false
    property bool authenticating: false
    property bool waitingForPassword: false
    property bool responseVisible: false
    property bool internalError: false

    signal unlocked

    readonly property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME")

    function reset() {
        password = ""
        message = "Enter your password to unlock"
        failed = false
        authenticating = false
        waitingForPassword = false
        responseVisible = false
        internalError = false
        if (pam.active) pam.abort()
    }

    function submit() {
        if (authenticating || password.length === 0) return

        failed = false
        internalError = false
        message = "Checking password…"
        if (waitingForPassword) {
            const response = password
            password = ""
            authenticating = true
            waitingForPassword = false
            pam.respond(response)
            return
        }

        if (pam.active) pam.abort()
        if (!pam.start()) {
            failed = true
            message = "Authentication service is unavailable"
        }
    }

    PamContext {
        id: pam
        configDirectory: "/etc/pam.d"
        config: "swaylock"

        onPamMessage: {
            root.responseVisible = responseVisible
            if (responseRequired) {
                if (root.password.length > 0) {
                    const response = root.password
                    root.password = ""
                    root.authenticating = true
                    pam.respond(response)
                } else {
                    root.waitingForPassword = true
                    root.message = message || "Enter your password to unlock"
                }
                return
            }

            if (messageIsError) {
                root.failed = true
                root.message = message || "Authentication failed"
            } else if (message) {
                root.message = message
            }
        }

        onCompleted: function(result) {
            root.authenticating = false
            root.waitingForPassword = false
            root.responseVisible = false
            if (result === PamResult.Success) {
                root.unlocked()
                return
            }

            root.password = ""
            root.failed = true
            if (!root.internalError) {
                root.message = result === PamResult.MaxTries
                    ? "Too many attempts. Try again."
                    : "Wrong password. Try again."
            }
        }

        onError: function(error) {
            root.authenticating = false
            root.waitingForPassword = false
            root.responseVisible = false
            root.internalError = true
            root.password = ""
            root.failed = true
            root.message = "Authentication is unavailable: " + PamError.toString(error)
        }
    }
}
