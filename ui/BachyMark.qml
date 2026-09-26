import QtQuick
import QtQuick.Shapes

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

    Shape {
        width: 1170
        height: 1100
        x: (root.width - width * root.markScale) / 2 - 40 * root.markScale
        y: (root.height - height * root.markScale) / 2 - 70 * root.markScale
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.markScale; yScale: root.markScale }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            // The item's position accounts for the SVG viewBox origin.
            PathSvg { path: "M608 133 C688 164 726 226 723 310 C720 405 674 490 608 564 L503 466 C567 376 650 233 608 133 Z M507 282 C412 300 350 376 360 468 C370 563 464 620 588 701 C719 788 828 894 852 1033 C881 972 861 857 799 775 C731 685 634 619 540 554 C449 492 431 384 507 282 Z M746 283 C824 305 891 371 894 450 C900 528 829 596 740 664 L648 589 C751 512 843 401 746 283 Z M416 608 L507 677 C435 755 389 851 369 989 C360 1065 277 1126 103 1096 C203 1032 216 959 253 862 C290 761 346 678 416 608 Z M520 686 L612 750 C487 844 430 911 393 1021 C374 948 394 851 432 785 C455 745 486 709 520 686 Z M838 609 C934 705 979 805 1017 905 C1052 1004 1081 1054 1150 1096 C1005 1115 903 1080 888 993 C868 864 827 779 754 688 Z" }
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
