//@ pragma ShellId bachy-taildrop-send-test
import QtQuick
import Quickshell
ShellRoot {
    id: root
    property int phase: 0
    property bool finished: false
    function finish(message) {
        if (finished) return
        finished = true
        console.log(message)
        Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }
    Taildrop {
        id: sender
        peers: [{ id: "peer", label: "Laptop", address: "laptop.example" }]
        sendCommand: "tailscale"
        onSendFinished: function(message, failed) {
            if (root.phase === 0) {
                if (failed || message !== "Sent to Laptop.") { root.finish("TAILDROP FAIL success=" + message); return }
                root.phase = 1
                Qt.callLater(function() { sender.send("peer", ["/tmp/failure file.txt"]) })
            } else if (root.phase === 1) {
                if (!failed || message.indexOf("exit 42") < 0) { root.finish("TAILDROP FAIL error=" + message); return }
                root.finish("TAILDROP PASS argv success failure overlap")
            }
        }
    }
    Timer {
        interval: 100; running: true
        onTriggered: {
            if (!sender.send("peer", ["/tmp/a file.txt"])) { root.finish("TAILDROP FAIL refused"); return }
            if (sender.send("peer", ["/tmp/overlap"])) root.finish("TAILDROP FAIL overlap")
        }
    }
    Timer { interval: 4000; running: true; onTriggered: root.finish("TAILDROP FAIL timeout") }
}
