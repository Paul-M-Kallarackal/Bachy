import QtQuick
import Quickshell
import "../ui/js/PreviewKeys.js" as PreviewKeys

ShellRoot {
    id: shell
    property string surface: Quickshell.env("MEDIA_OPTIONAL_SURFACE")
    property string mode: Quickshell.env("MEDIA_OPTIONAL_MODE")
    property string kind: Quickshell.env("MEDIA_OPTIONAL_KIND")
    property string fixture: Quickshell.env("MEDIA_OPTIONAL_FIXTURE")
    property int phase: 0
    property int elapsed: 0
    function done(message) { console.log("MEDIAOPTIONAL " + message); Qt.quit() }
    function check(ok, message) {
        if (!ok) { done("FAIL " + surface + ": " + message); return false }
        console.log("MEDIAOPTIONAL PASS " + surface + ": " + message)
        return true
    }
    function reader(item) {
        if (item.playerComponent !== undefined) return item
        for (var i = 0; i < item.children.length; i++) {
            var found = reader(item.children[i])
            if (found) return found
        }
        return null
    }
    function load(path) {
        if (surface === "column") {
            view.item.path = path
            view.item.row = {n: "sample." + (kind === "audio" ? "wav" : "mp4"), d: false, s: 500, i: kind === "audio" ? "audio-x-generic" : "video-x-generic", k: 0, m: 1700000000}
            view.item.selectionCount = 1
            view.item.kindName = kind === "audio" ? "WAV audio" : "MPEG-4 video"
            view.item.meta = {owner: "test"}
        } else view.item.open(path, kind === "audio" ? "audio-x-generic" : "video-x-generic", 500, kind)
    }
    FloatingWindow {
        implicitWidth: shell.surface === "column" ? 220 : 800
        implicitHeight: 600
        color: "white"
        Loader {
            id: view
            anchors.fill: parent
            source: "file://" + Quickshell.env("MEDIA_OPTIONAL_UI")
                + (shell.surface === "column" ? "/PreviewColumn.qml" : "/Preview.qml")
            onLoaded: shell.load(shell.fixture)
            onStatusChanged: if (status === Loader.Error) shell.done("FAIL surface could not load")
        }
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            shell.elapsed += interval
            if (shell.elapsed > 10000) { shell.done("FAIL timeout phase " + shell.phase); stop(); return }
            var p = view.item
            if (!p) return
            var column = shell.surface === "column"
            if (shell.phase === 0) {
                if (column) {
                    if (!p.mediaStripItem()) return
                    if (!shell.check(!p.playerLoaded(), "selection alone constructs no player")) return
                    p.mediaStripItem().toggled()
                }
                shell.phase = 1
            } else if (shell.phase === 1) {
                var actual = shell.reader(p)
                if (!actual) return
                if (shell.mode !== "present") {
                    if (!actual.unavailable || !actual.openButton) return
                    if (!shell.check(actual.guidance.indexOf(shell.mode === "missing" ? "Install qt6-multimedia" : "could not start") >= 0, "specific recovery text")) return
                    if (!shell.check(!actual.failed && actual.openButton.visible && actual.visible, "missing module has a visible action, not a corrupt-file error")) return
                    actual.openButton.forceActiveFocus()
                    var point = actual.openButton.mapToItem(actual, 0, 0)
                    if (!shell.check(point.y >= 0 && point.y + actual.openButton.height <= actual.height + 1, "focused external action scrolls into the narrow viewport")) return
                    if (!column && !shell.check(!p.stripVisible, "unavailable playback hides transport")) return
                    if (column) p.mediaStripItem().toggled()
                    else PreviewKeys.act("open", {preview: p})
                    shell.phase = 2
                } else {
                    if (actual.duration <= 0 || actual.position < 50) return
                    if (!shell.check(!actual.unavailable && !actual.failed, "installed support actually decodes and plays")) return
                    actual.togglePlay()
                    actual.seekTo(1000)
                    shell.phase = 3
                }
            } else if (shell.phase === 3) {
                var player = shell.reader(p)
                if (player.status !== "paused" || player.position < 1000) return
                if (!shell.check(true, "pause and seek work through the optional boundary")) return
                shell.load(shell.fixture + ".corrupt")
                if (column) p.mediaStripItem().toggled()
                shell.phase = 5
            } else if (shell.phase === 5) {
                var broken = shell.reader(p)
                if (!broken || !broken.failed) return
                if (!shell.check(!broken.unavailable, "corrupt media keeps its playback error")) return
                shell.phase = 4
            } else if (shell.phase === 2) {
                var shots = Quickshell.env("MEDIA_OPTIONAL_SHOTS")
                shell.phase = 6
                if (shots && shell.mode === "missing") {
                    view.item.grabToImage(function(result) {
                        result.saveToFile(shots + "/media-" + shell.surface + "-" + shell.kind + ".png")
                        shell.phase = 4
                    })
                } else shell.phase = 4
            } else if (shell.phase === 4) {
                if (column) p.path = shell.fixture + ".closed"
                else p.close()
                if (!shell.check(column ? !p.playerLoaded() : !p.mediaLoaded(), "changing or closing the preview unloads playback")) return
                stop(); shell.done("DONE " + shell.surface + " " + shell.mode + " " + shell.kind)
            }
        }
    }
}
