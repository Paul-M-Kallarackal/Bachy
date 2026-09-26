.import "../../ui/js/Palette.js" as Palette
.import "../../ui/js/Contrast.js" as Contrast
// Test the shipped standalone palette, without requiring another desktop's files.
function run(check) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../packaging/colors.toml"), false)
    request.send()
    check("the standalone palette ships with Bachy", request.status, 200)
    var p = Palette.parse(request.responseText)
    check("the palette is valid", Palette.isPalette(p), true)
    for (var key of ["foreground", "muted", "accent", "urgent", "cyan", "green"])
        check(key + " is readable on the background", Contrast.ratio(p[key], p.background) >= 4.5, true)
    check("body text remains readable on selection", Contrast.ratio(p.foreground, "#DBEAFE") >= 4.5, true)
}
