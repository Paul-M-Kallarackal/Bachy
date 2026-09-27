import QtQuick
import "." as Bachy

// Compile the heavy module only when playback is requested. An absent package
// must not stop either preview surface, or be mistaken for an unplayable file.
Item {
    id: root
    property string path: ""
    property string kind: "audio"
    property int size: 0
    property string kindName: ""
    property int rate: 0
    property bool autoStart: true
    property bool actionFocused: false
    property var playerComponent: null
    readonly property bool unavailable: playerComponent !== null && playerComponent.status === Component.Error
    readonly property string loadError: unavailable ? playerComponent.errorString() : ""
    readonly property bool missingSupport: /module ["']QtMultimedia["'] is not installed/.test(loadError)
    readonly property string guidance: missingSupport
        ? "Install qt6-multimedia for audio and video playback, then reopen Bachy."
        : "Media preview could not start. Open the file in another application."
    readonly property bool failed: player.item ? player.item.failed : false
    readonly property string status: unavailable ? guidance : player.item ? player.item.status : "loading"
    readonly property real position: player.item ? player.item.position : 0
    readonly property real duration: player.item ? player.item.duration : 0
    readonly property var openButton: fallback.item ? fallback.item.openButton : null
    function openExternally() { if (root.openButton) root.openButton.activated() }
    function togglePlay() { if (player.item) player.item.togglePlay(); else if (unavailable) openExternally() }
    function seekTo(ms) { if (player.item) player.item.seekTo(ms) }
    Component.onCompleted: playerComponent = Qt.createComponent("PreviewMedia.qml")

    Loader {
        id: player
        anchors.fill: parent
        sourceComponent: root.playerComponent && root.playerComponent.status === Component.Ready
            ? root.playerComponent : null
        onLoaded: {
            item.autoStart = root.autoStart
            item.kind = Qt.binding(function () { return root.kind })
            item.size = Qt.binding(function () { return root.size })
            item.kindName = Qt.binding(function () { return root.kindName })
            item.rate = Qt.binding(function () { return root.rate })
            item.path = Qt.binding(function () { return root.path })
        }
    }
    Loader {
        id: fallback
        anchors.fill: parent
        active: root.unavailable
        sourceComponent: Component {
            Bachy.PreviewUnavailable {
                path: root.path
                title: "Media preview unavailable"
                detail: root.guidance
                actionFocused: root.actionFocused
            }
        }
    }
}
