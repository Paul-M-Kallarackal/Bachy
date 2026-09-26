import QtQuick
import Quickshell
import Quickshell.Io
import "js/Taildrop.js" as TaildropJs

// The context menu's own Service, the same shape as ui/NetworkMounts.qml: this is the only thing
// here that touches tailscale, ui/ContextMenu.qml only reads "peers" and renders it.
Item {
    id: root

    property var peers: []
    property string reason: "checking"
    property string sendCommand: ""
    property bool checking: false
    property bool _awaitingStart: false
    // The OEM Tailscale service's pollWatchdog bounds status queries at fifteen seconds.
    readonly property int statusTimeoutSeconds: 15
    signal refreshed()
    signal sendFinished(string message, bool failed)
    property bool sending: false
    property bool _sendAwaitingStart: false
    property string _sendLabel: ""
    // onExited can race the StdioCollector's own text, see ui/NetworkMounts.qml's header comment.
    property string _statusOutput: ""
    property string _statusError: ""

    function refresh(facts) {
        if (checking) return false
        peers = []
        var provider = facts.taildrop || {}, sender = facts.taildropSend || {}
        sendCommand = sender.command || ""
        reason = provider.reason || sender.reason || "checking"
        if (!provider.command || !sendCommand) return true
        checking = true
        _awaitingStart = true
        _statusOutput = ""
        _statusError = ""
        statusProcess.command = ["timeout", "--signal=KILL", String(statusTimeoutSeconds), provider.command, "status", "--json"]
        statusProcess.running = true
        return true
    }

    // Keep the CLI process observable so its result reaches the pane status bar.
    function send(peerId, paths) {
        var peer = TaildropJs.byId(root.peers, peerId)
        if (sending) { reason = "a send is already in progress"; return false }
        if (!peer || !sendCommand || checking || !paths.length) return false
        _sendLabel = peer.label
        sending = true
        _sendAwaitingStart = true
        sendProcess.command = [sendCommand, "file", "cp", "--"].concat(paths).concat([peer.address + ":"])
        sendProcess.running = true
        return true
    }

    // ui/Pane.qml's own dispatch-confirmation message reads a name, not the id chosen() carries.
    function labelFor(peerId) {
        var peer = TaildropJs.byId(root.peers, peerId)
        return peer ? peer.label : "that peer"
    }

    Process {
        id: sendProcess
        onStarted: root._sendAwaitingStart = false
        onRunningChanged: {
            if (root._sendAwaitingStart && !running) {
                root._sendAwaitingStart = false
                root.sending = false
                root.sendFinished("Tailscale could not start.", true)
            }
        }
        onExited: function(exitCode) {
            root._sendAwaitingStart = false
            root.sending = false
            root.sendFinished(exitCode === 0 ? "Sent to " + root._sendLabel + "."
                : "Taildrop to " + root._sendLabel + " failed (exit " + exitCode + ").", exitCode !== 0)
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
            onStreamFinished: root._statusOutput = text
        }
        stderr: StdioCollector { id: statusErr; waitForEnd: true; onStreamFinished: root._statusError = text }
        onStarted: root._awaitingStart = false
        onRunningChanged: {
            if (root._awaitingStart && !running) {
                root._awaitingStart = false
                root.checking = false
                root.reason = "Tailscale status helper could not start"
                root.refreshed()
            }
        }
        onExited: function (exitCode) {
            root._awaitingStart = false
            var state = TaildropJs.status(statusOut.text || root._statusOutput, exitCode,
                exitCode === 137 || exitCode === 9 ? "Tailscale status was interrupted or timed out" : statusErr.text || root._statusError)
            root.peers = state.peers
            root.reason = state.reason
            root.checking = false
            root.refreshed()
        }
    }
}
