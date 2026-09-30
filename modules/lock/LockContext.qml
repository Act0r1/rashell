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
    property int failures: 0
    property real retryAt: 0
    property real clock: Date.now()
    readonly property int cooldownSeconds: Math.max(0, Math.ceil((retryAt - clock) / 1000))

    signal unlocked

    function cooldownFor(count: int): int {
        return count < 3 ? 0 : Math.min(30000, 1000 * Math.pow(2, count - 3))
    }

    function cooldownMessage(): string {
        return "Too many attempts. Try again in " + cooldownSeconds + " s"
    }

    readonly property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME")

    function reset() {
        password = ""
        message = "Enter your password to unlock"
        failed = false
        authenticating = false
        waitingForPassword = false
        responseVisible = false
        internalError = false
        failDelay.stop()
        if (pam.active) pam.abort()
    }

    function submit() {
        if (authenticating || password.length === 0) return
        clock = Date.now()
        if (cooldownSeconds > 0) {
            failed = false
            message = cooldownMessage()
            failed = true
            return
        }

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

    Timer {
        id: failDelay
        property int result
        interval: 1000
        onTriggered: {
            root.authenticating = false
            root.failures++
            root.clock = Date.now()
            root.retryAt = root.clock + root.cooldownFor(root.failures)
            if (!root.internalError) {
                root.message = root.cooldownSeconds > 0 ? root.cooldownMessage()
                    : result === PamResult.MaxTries ? "Too many attempts. Try again."
                    : "Wrong password. Try again."
            }
            root.failed = true
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.retryAt > root.clock
        onTriggered: {
            root.clock = Date.now()
            if (root.message.indexOf("Too many attempts. Try again in") === 0) {
                root.message = root.cooldownSeconds > 0 ? root.cooldownMessage() : "Try again."
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/modules/lock/pam"
        config: "rashell-lock"

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
            root.waitingForPassword = false
            root.responseVisible = false
            root.password = ""
            if (result === PamResult.Success) {
                root.authenticating = false
                root.failures = 0
                root.retryAt = 0
                root.unlocked()
                return
            }

            root.authenticating = true
            failDelay.result = result
            failDelay.start()
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
