pragma Singleton
import QtQuick
import Quickshell
Singleton {
    function alpha(color, opacity) { return Qt.rgba(color.r, color.g, color.b, opacity) }
    function fileUrl(path) { return "file://" + String(path).split("/").map(encodeURIComponent).join("/") }
}
