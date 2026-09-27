import QtQuick
import "." as Bachy

// Keep the optional QtQuick.Pdf import behind a component boundary. Compile once,
// on the first PDF, so missing support costs nothing while browsing other files.
Item {
    id: root
    property string path: ""
    property bool active: false
    property int page: 0
    property Item viewport: null
    property bool actionFocused: false
    property var documentComponent: null
    readonly property bool unavailable: root.active && documentComponent !== null
        && documentComponent.status === Component.Error
    readonly property string loadError: unavailable ? documentComponent.errorString() : ""
    readonly property bool missingSupport: /module ["']QtQuick\.Pdf["'] is not installed/.test(loadError)
    readonly property string guidance: missingSupport
        ? "Install qt6-webengine for PDF preview, then reopen Bachy."
        : "PDF preview could not start. Open the file in another application."
    readonly property int pageCount: reader.item ? reader.item.pageCount : 0
    readonly property bool failed: reader.item ? reader.item.failed : false
    readonly property int shownPage: reader.item ? reader.item.shownPage : -1
    readonly property int drawnPage: reader.item ? reader.item.drawnPage : root.page
    readonly property bool fellBack: reader.item ? reader.item.fellBack : false
    readonly property var openButton: fallback.item ? fallback.item.openButton : null
    signal openRequested(string path)

    function prepare() {
        if (root.active && root.documentComponent === null)
            root.documentComponent = Qt.createComponent("PreviewPdf.qml")
    }
    function turn(delta) {
        if (root.pageCount > 0) root.page = Math.max(0, Math.min(root.pageCount - 1, root.page + delta))
    }
    onActiveChanged: prepare()
    onPathChanged: root.page = 0
    // PreviewPdf clamps its own page when the document opens, which would replace
    // a QML binding. Forward each requested turn explicitly instead.
    onPageChanged: if (reader.item) reader.item.page = root.page
    onPageCountChanged: if (root.pageCount > 0) root.page = Math.min(root.page, root.pageCount - 1)
    Component.onCompleted: prepare()

    Loader {
        id: reader
        anchors.fill: parent
        active: root.active
        sourceComponent: root.documentComponent && root.documentComponent.status === Component.Ready
            ? root.documentComponent : null
        onLoaded: {
            item.path = Qt.binding(function() { return root.path })
            item.page = root.page
            item.viewport = Qt.binding(function() { return root.viewport })
            item.active = true
        }
    }
    Loader {
        id: fallback
        anchors.fill: parent
        active: root.unavailable
        sourceComponent: Component {
            Bachy.PreviewUnavailable {
                path: root.path
                detail: root.guidance
                actionFocused: root.actionFocused
                onOpenRequested: root.openRequested(root.path)
            }
        }
    }
}
