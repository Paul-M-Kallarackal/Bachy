import QtQuick
Rectangle {
    property var borderSpec: ({color: "#E1E5EB", width: 1})
    property real padding: 16
    readonly property real contentTopInset: padding + border.width
    readonly property real contentBottomInset: contentTopInset
    readonly property real contentLeftInset: contentTopInset
    readonly property real contentRightInset: contentTopInset
    border.color: borderSpec.color
    border.width: borderSpec.width
}
