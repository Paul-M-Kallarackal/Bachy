pragma Singleton
import QtQuick
import Quickshell
import "js/Palette.js" as Palette
Singleton {
    property color background: "#FFFFFF"
    property color foreground: "#28303D"
    property color accent: "#1E40AF"
    property color urgent: "#991B1B"
    function loadColors(body) {
        var p = Palette.parse(body)
        background = Palette.pick(p, ["background"], "#FFFFFF")
        foreground = Palette.pick(p, ["foreground"], "#28303D")
        accent = Palette.pick(p, ["accent"], "#1E40AF")
        urgent = Palette.pick(p, ["urgent", "red"], "#991B1B")
    }
}
