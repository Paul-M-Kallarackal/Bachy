pragma Singleton
import QtQuick
import Quickshell
Singleton {
    readonly property QtObject font: QtObject {
        readonly property string family: Quickshell.env("BACHY_FONT") || "Noto Sans Mono"
        readonly property string resolvedFamily: family
        readonly property int baseSize: Math.max(10, Math.min(24, Number(Quickshell.env("BACHY_FONT_SIZE")) || 14))
        readonly property int body: baseSize
        readonly property int bodySmall: Math.round(baseSize * 0.917)
        readonly property int caption: Math.round(baseSize * 0.833)
        readonly property int icon: Math.round(baseSize * 1.143)
    }
    readonly property QtObject spacing: QtObject {
        readonly property int hairline: 1
        readonly property int rowPaddingX: 16
        readonly property int controlPaddingY: 6
        readonly property int rowGap: 8
        readonly property int panelGap: 16
    }
    readonly property int cornerRadius: 8
    readonly property int normalBorderWidth: 1
    readonly property real hoverFillAlpha: 0.08
    readonly property real selectionFillAlpha: 0.14
    readonly property color normalFill: "#F5F6F9"
    readonly property color hoverFill: Util.alpha(Color.accent, hoverFillAlpha)
    readonly property color selectedFill: "#DBEAFE"
    readonly property color selectedAccentFill: "#DBEAFE"
    readonly property color selectionFill: Util.alpha(Color.accent, selectionFillAlpha)
    readonly property color hoverBorderColor: "#858B96"
    function space(px) { return Math.round(px * font.baseSize / 12) }
}
