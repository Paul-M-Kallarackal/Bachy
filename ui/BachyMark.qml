import QtQuick

// Bachy's abstract fugue emblem, matching packaging/local.bachy.FileManager.svg.
// Filled ribbons keep the approved silhouette legible in small menu and settings slots.
Item {
    id: root

    property color color: Theme.color.accent
    readonly property real markScale: Math.min(root.width, root.height) / 1170
    readonly property bool settled: !draw.running && root.opacity === 1

    // EmptyState drives the repeat alongside its caption. Reduced motion shows the full mark.
    function replay() {
        draw.stop()
        if (Theme.reducedMotion)
            root.opacity = 1
        else
            draw.restart()
    }

    Loader {
        anchors.fill: parent
        active: root.visible
        source: "FugueShape.qml"
        onLoaded: {
            item.markScale = Qt.binding(function () { return root.markScale })
            item.color = Qt.binding(function () { return root.color })
        }
    }

    SequentialAnimation {
        id: draw
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 180; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 200 }
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutQuad }
    }

    onVisibleChanged: {
        if (root.visible) root.replay()
        else { draw.stop(); root.opacity = 1 }
    }
    Component.onCompleted: if (root.visible) root.replay()
    Connections {
        target: Theme
        function onReducedMotionChanged() { if (Theme.reducedMotion) root.replay() }
    }
}
