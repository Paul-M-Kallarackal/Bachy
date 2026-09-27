import QtQuick
import "." as Bachy

// Created only for unavailable PDF support, never on ordinary window startup.
Item {
    id: root
    property string path: ""
    property string detail: ""
    property bool actionFocused: false
    property string openError: ""
    readonly property alias openButton: open
    signal openRequested(string path)
    onPathChanged: openError = ""

    Column {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 2 * Theme.spacing.gap)
        spacing: Theme.spacing.gap
        Text {
            width: parent.width
            text: "PDF preview unavailable"
            color: Theme.color.foreground
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            text: root.openError || root.detail
            color: root.openError ? Theme.color.error : Theme.color.muted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.caption
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
        Bachy.DialogButton {
            id: open
            anchors.horizontalCenter: parent.horizontalCenter
            label: "Open externally"
            primary: root.actionFocused || activeFocus
            available: root.path.length > 0
            activeFocusOnTab: true
            Keys.onReturnPressed: if (available) activated()
            Keys.onEnterPressed: if (available) activated()
            onActivated: {
                root.openError = ""
                root.openRequested(root.path)
                opener.open(root.path)
            }
        }
    }
    Bachy.Opener {
        id: opener
        onFailed: root.openError = "Could not open this file. Check its default application."
        onBusy: root.openError = "An application is still opening. Try again shortly."
        onIsDirectory: root.openError = "This path is now a folder. Select the file again."
    }
}
