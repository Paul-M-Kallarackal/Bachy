import QtQuick
import Quickshell
import "../ui/js/PreviewKeys.js" as PreviewKeys

ShellRoot {
    id: shell
    property string surface: Quickshell.env("PDF_OPTIONAL_SURFACE")
    property string mode: Quickshell.env("PDF_OPTIONAL_MODE")
    property string fixture: Quickshell.env("PDF_OPTIONAL_FIXTURE")
    property int phase: 0
    property int elapsed: 0
    function done(message) { console.log("PDFOPTIONAL " + message); Qt.quit() }
    function check(ok, message) {
        if (!ok) { done("FAIL " + surface + ": " + message); return false }
        console.log("PDFOPTIONAL PASS " + surface + ": " + message)
        return true
    }
    function state() {
        var p = view.item
        if (!p) return null
        return surface === "column" ? p : p.pdfItem
    }
    function reader(item) {
        if (item.documentComponent !== undefined) return item
        for (var i = 0; i < item.children.length; i++) {
            var found = reader(item.children[i])
            if (found) return found
        }
        return null
    }
    function load(path) {
        if (surface === "column") {
            view.item.path = path
            view.item.row = {n: "sample.pdf", d: false, s: 500, i: "file-text", k: 0, m: 1700000000}
            view.item.selectionCount = 1
            view.item.kindName = "PDF document"
            view.item.meta = {owner: "test"}
        } else view.item.open(path, "file-text", 500, "PDF document")
    }
    FloatingWindow {
        implicitWidth: shell.surface === "column" ? 300 : 800
        implicitHeight: 600
        color: "white"
        Loader {
            id: view
            anchors.fill: parent
            source: "file://" + Quickshell.env("PDF_OPTIONAL_UI")
                + (shell.surface === "column" ? "/PreviewColumn.qml" : "/Preview.qml")
            onLoaded: shell.load(shell.fixture + "/sample.pdf")
            onStatusChanged: if (status === Loader.Error) shell.done("FAIL surface could not load")
        }
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            shell.elapsed += interval
            if (shell.elapsed > 10000) { shell.done("FAIL timeout phase " + shell.phase); stop(); return }
            var p = shell.state()
            if (!p) return
            var column = shell.surface === "column"
            var unavailable = column ? p.pdfUnavailable : p.unavailable
            var count = column ? p.pdfPages : p.pageCount
            if (shell.phase === 0) {
                if (shell.mode !== "present") {
                    if (!unavailable || p.pdfControls.length === 0 || !p.pdfControls[0]) return
                    if (!shell.check(count === 0, "missing support leaves no fake pages")) return
                    if (!shell.check(!(column ? p.pdfFailed : p.failed), "module failure differs from corrupt document")) return
                    if (!column && !shell.check(p.guidance.indexOf(shell.mode === "missing" ? "Install qt6-webengine" : "could not start") >= 0, "specific recovery text")) return
                    p.pdfControlIndex = 0
                    PreviewKeys.pdfAction("open", p)
                    console.log("PDFOPTIONAL PASS " + shell.surface + ": external-open action invoked")
                    shell.phase = 2
                } else {
                    if (count !== 2) return
                    if (!shell.check(!unavailable, "installed PDF support loads two real pages")) return
                    p.turnPage(1)
                    shell.phase = 1
                }
            } else if (shell.phase === 1) {
                var actual = shell.reader(p)
                if (!actual || actual.shownPage !== 1) return
                var page = column ? p.pdfPage() : p.page
                if (!shell.check(page === 1, "page navigation actually renders the second page")) return
                shell.load(shell.fixture + "/corrupt.pdf")
                shell.phase = 3
            } else if (shell.phase === 2) {
                var shots = Quickshell.env("PDF_OPTIONAL_SHOTS")
                if (shots && shell.mode === "missing") {
                    shell.phase = 5
                    view.item.grabToImage(function(result) {
                        result.saveToFile(shots + "/pdf-" + shell.surface + ".png")
                        shell.phase = 4
                    })
                } else shell.phase = 4
            } else if (shell.phase === 4) {
                if (!column) {
                    view.item.close()
                    if (!shell.check(!view.item.active && view.item.pdfItem === null, "Quick Look closes and unloads")) return
                }
                stop(); shell.done("DONE " + shell.surface + " " + shell.mode)
            } else if (shell.phase === 3) {
                if (!(column ? p.pdfFailed : p.failed)) return
                if (!shell.check(!unavailable, "corrupt PDF keeps its read-error state")) return
                stop(); shell.done("DONE " + shell.surface + " " + shell.mode)
            }
        }
    }
}
