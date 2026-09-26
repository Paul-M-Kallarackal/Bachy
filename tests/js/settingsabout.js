.import "../../ui/js/Settings.js" as Settings
.import "../../ui/js/Update.js" as Update
.import "../../ui/js/MakeDefault.js" as MakeDefault
.import "../../ui/js/SettingsAbout.js" as SettingsAbout

// The About section's Updates group: the Update Bachy row, the switch that governs the automatic checks, and the note line; then This box's Make Bachy the default row.

function find(rows, id) {
    return rows.filter(function (row) { return row.id === id })[0] || {}
}

function about(update, data) {
    return Settings.rows("about", { about: { update: update }, data: data || {} })
}

function answered(line) {
    return Update.answered(Update.checking(Update.idle()), line, 1000)
}

// The rows between the Updates heading and the next one, as kind:label, for a status.
function group(update) {
    var rows = about(update)
    var labels = rows.map(function (row) { return row.kind + ":" + row.label })
    var from = labels.indexOf("group:Updates") + 1
    return labels.slice(from, labels.indexOf("group:This box")).join(",")
}

function run(check) {
    var rows = about(undefined)
    check("the fork identifies itself", rows[0].label + "|" + rows[0].value, "Bachy|A file manager for CachyOS")
    check("the personal build cannot install an upstream update", group(undefined), "fact:Updates")
    check("there is no updater action", find(rows, "updateBachy").id, undefined)
    check("there is no automatic upstream check", find(rows, "updates.autoCheck").id, undefined)
    check("upstream attribution remains linked", find(rows, "reportIssue").url, "https://github.com/thisisgm/flea/issues")
    runDefault(check)
}

var BACHY = "local.bachy.FileManager.desktop"
var NAUTILUS = "org.gnome.Nautilus.desktop"
var CLAIM = ["--default"]
var RELEASE = ["--default", "off"]
// The number the run's own re-read carries, one past the read About opened with.
var REREAD = 2

// A file of this tree, read the way tests/js/themes.js reads colors.toml; "" when it is not there.
function source(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../" + path), false)
    request.send()
    return String(request.responseText || "")
}

// The one "bachy: " sentence a Rust function prints on stderr, its {} filled, with the newline eprintln! adds; "" unless there is exactly one.
// Sample input: eprintln!("bachy: no portal backend is installed, so the file chooser step was skipped");
function spoken(text, header, fill) {
    var start = text.indexOf(header)
    var body = start < 0 ? "" : text.substring(start, text.indexOf("\n}\n", start))
    var found = body.match(/eprintln!\(\s*"bachy: [^"]*"/g) || []
    return found.length === 1 ? found[0].substring(found[0].indexOf("\"") + 1, found[0].length - 1).replace("{}", fill) + "\n" : ""
}

function box(handler, claim) {
    return Settings.rows("about", { about: { handler: handler, claim: claim } })
}

// The rows from the File manager fact to Keyboard sheet, as kind:label, the note included when there is one.
function boxGroup(handler, claim) {
    var labels = box(handler, claim).map(function (row) { return row.kind + ":" + row.label })
    var from = labels.indexOf("fact:File manager")
    return labels.slice(from, labels.indexOf("action:Keyboard sheet")).join(",")
}

// The line under the row, or {} when the next row is not a note.
function noteOf(handler, claim) {
    var rows = box(handler, claim)
    var next = rows[rows.map(function (row) { return row.id }).indexOf("makeDefault") + 1]
    return next.kind === "hint" ? next : {}
}

// The row and its note as on|inert|note|role|elide, the three note fields empty when there is none.
function look(handler, claim) {
    var row = find(box(handler, claim), "makeDefault"), note = noteOf(handler, claim)
    return [row.on, row.inert, note.label || "", note.role || "", note.elide || ""].join("|")
}

// A run that has exited, whose handler has been read again, and whose portal restart, if it asked for one, answered.
function after(args, code, stderr, restartOk) {
    var read = MakeDefault.settled(MakeDefault.finished(MakeDefault.started(MakeDefault.idle(), args), code, stderr, REREAD), REREAD)
    return read.restarting ? MakeDefault.restarted(read, restartOk !== false) : read
}

function runDefault(check) {
    // The two sentences MakeDefault.js reads are the binary's own, taken from the source rather than copied here.
    var defaults = source("src/defaults.rs"), main = source("src/main.rs")
    // Sample input: pub const DESKTOP_ID: &str = "local.bachy.FileManager.desktop";
    var rustId = (defaults.match(/pub const DESKTOP_ID: &str = "([^"]*)"/) || [])[1]
    var refusal = spoken(defaults, "pub fn claim() -> i32 {", rustId)
    var skipped = spoken(main, "fn claim_both() -> i32 {", "")
    check("the box is ticked by the very id src/defaults.rs claims", MakeDefault.DESKTOP_ID, rustId)
    check("the refusal is defaults::claim()'s own bachy: line, and it carries what MakeDefault.js reads",
          refusal.indexOf("bachy: " + rustId + " ") === 0 && refusal.indexOf(MakeDefault.UNINSTALLED) > 0, true)
    check("the partly line is claim_both()'s own bachy: line, word for word what MakeDefault.js reads",
          skipped, "bachy: " + MakeDefault.SKIPPED + "\n")

    check("the row sits directly under the File manager fact, which stays a fact",
          boxGroup(NAUTILUS, undefined), "fact:File manager,check:Make Bachy the default")
    var row = find(box(NAUTILUS, undefined), "makeDefault")
    check("it is the label and the box alone, with no caption and no mark", String(row.caption) + "|" + String(row.glyph), "undefined|undefined")
    check("a check the cursor stops on", Settings.focusable(row) + "|" + row.kind, "true|check")
    check("off: unticked, live, and no note", look(NAUTILUS, undefined), "false|false|||")
    check("off: a press claims", JSON.stringify(MakeDefault.press(NAUTILUS, MakeDefault.idle())), JSON.stringify(CLAIM))
    check("nothing answered reads as off, not as Bachy", look("", undefined), "false|false|||")

    check("on: ticked by xdg-mime's answer, with the note in the foreground on one eliding line", look(BACHY, MakeDefault.idle()),
          "true|false|Folders, Show in folder and file dialogs open Bachy.|foreground|right")
    check("on: a press hands folders back", JSON.stringify(MakeDefault.press(BACHY, MakeDefault.idle())), JSON.stringify(RELEASE))
    check("the note is a line the cursor steps over", noteOf(BACHY, undefined).kind + "|" + Settings.focusable(noteOf(BACHY, undefined)), "hint|false")

    var claiming = MakeDefault.started(MakeDefault.idle(), CLAIM)
    check("working on a claim: inert, the box still the truth, the note muted",
          look(NAUTILUS, claiming), "false|true|Making Bachy the default|muted|right")
    check("working on a release says so", look(BACHY, MakeDefault.started(MakeDefault.idle(), RELEASE)), "true|true|Handing folders back|muted|right")
    check("a press while a run is in flight runs nothing", MakeDefault.press(NAUTILUS, claiming), null)
    check("and the row stays a stop so the cursor does not jump", Settings.focusable(find(box(NAUTILUS, claiming), "makeDefault")), true)
    check("an exited run is still working until the handler is read again",
          MakeDefault.state(NAUTILUS, MakeDefault.finished(claiming, 0, "", REREAD)), "working")
    check("the re-read answer decides the box, not the press", look(NAUTILUS, after(CLAIM, 0, "")), "false|false|||")
    check("a read landing while bachy still runs, About opening in another window, ends nothing",
          MakeDefault.state(NAUTILUS, MakeDefault.settled(claiming, 1)) + "|" + MakeDefault.press(NAUTILUS, MakeDefault.settled(claiming, 1)), "working|null")
    var waiting = MakeDefault.finished(claiming, 0, "", REREAD)
    check("nor does one begun before bachy exited, which may predate what it wrote",
          MakeDefault.state(BACHY, MakeDefault.restarted(MakeDefault.settled(waiting, REREAD - 1), true)), "working")
    check("the read begun after the exit is the one that does",
          MakeDefault.state(BACHY, MakeDefault.restarted(MakeDefault.settled(waiting, REREAD), true)), "on")
    check("an exit and its text join in either order, an empty text counting as said",
          [MakeDefault.whole(MakeDefault.landed({}, { code: 0 })), MakeDefault.whole(MakeDefault.landed({}, { text: "" })),
           JSON.stringify(MakeDefault.landed(MakeDefault.landed({}, { code: 1 }), { text: "" })),
           JSON.stringify(MakeDefault.landed(MakeDefault.landed({}, { text: "" }), { code: 1 })),
           MakeDefault.whole(MakeDefault.landed(MakeDefault.landed({}, { text: "" }), { code: 1 }))].join("|"),
          'false|false|{"code":1,"text":""}|{"text":"","code":1}|true')

    check("the portal restart is exactly systemctl's try-restart of the user unit", MakeDefault.RESTART.join(" "),
          "systemctl --user try-restart xdg-desktop-portal.service")
    check("a claim, a partly claim and a release that went through each ask for it",
          [MakeDefault.finished(claiming, 0, "", REREAD).restarting,
           MakeDefault.finished(claiming, 0, skipped, REREAD).restarting,
           MakeDefault.finished(MakeDefault.started(MakeDefault.idle(), RELEASE), 0, "", REREAD).restarting].join("|"), "true|true|true")
    check("a failed run and a refused one do not",
          MakeDefault.finished(claiming, 1, "bachy: no\n", REREAD).restarting + "|" + MakeDefault.finished(claiming, 1, refusal, REREAD).restarting, "false|false")
    var exited = MakeDefault.finished(claiming, 0, "", REREAD)
    check("still working after the re-read while the restart runs", MakeDefault.state(BACHY, MakeDefault.settled(exited, REREAD)), "working")
    check("and after the restart while the re-read runs", MakeDefault.state(BACHY, MakeDefault.restarted(exited, true)), "working")
    check("either order ends the run",
          MakeDefault.settled(MakeDefault.restarted(exited, true), REREAD).running + "|" + MakeDefault.restarted(MakeDefault.settled(exited, REREAD), true).running,
          "false|false")

    // ui/ViewState.qml's writer rule: a program that cannot start raises no exited, only running going false.
    check("running going false with no status is a program that never ran, never one whose exit landed or one starting",
          [MakeDefault.neverRan({}, false), MakeDefault.neverRan({ text: "" }, false), MakeDefault.neverRan({ code: 0 }, false),
           MakeDefault.neverRan({}, true)].join("|"), "true|true|false|false")
    var unread = MakeDefault.landed({}, MakeDefault.NEVER_RAN)
    var manager = box(MakeDefault.handlerOf(unread), undefined).filter(function (row) { return row.label === "File manager" })[0] || {}
    check("an xdg-mime that never ran is a whole answer at once, stating no handler, so File manager reads Not reported",
          MakeDefault.whole(unread) + "|" + manager.value + "|" + MakeDefault.handlerOf({ code: 0, text: " " + BACHY + "\n" })
          + "|" + MakeDefault.handlerOf({ code: 3, text: BACHY + "\n" }), "true|Not reported|" + BACHY + "|")
    check("and as a run's own re-read it ends the run unticked, not working",
          look(MakeDefault.handlerOf(unread), MakeDefault.restarted(MakeDefault.settled(exited, REREAD), true)), "false|false|||")
    var dead = MakeDefault.unstarted(claiming, ["/usr/bin/bachy", "--default"])
    check("a bachy that never ran fails at once, naming the command, with no re-read or restart owed",
          look(NAUTILUS, dead) + "|" + dead.reading + "|" + dead.restarting,
          "false|false|/usr/bin/bachy --default could not start|error|right|false|false")
    check("and the next press tries again", JSON.stringify(MakeDefault.press(NAUTILUS, dead)), JSON.stringify(CLAIM))
    var restarting = MakeDefault.settled(exited, REREAD)
    check("a systemctl that never ran gives the restart-failed note and ends the run",
          restarting.restarting + "|" + look(BACHY, MakeDefault.restartStopped(restarting, false)),
          "true|true|false|File dialogs follow after xdg-desktop-portal restarts.|foreground|right")
    check("and one that exited is not taken for one that never ran when its running goes false",
          look(BACHY, MakeDefault.restartStopped(MakeDefault.restarted(restarting, true), false)), look(BACHY, MakeDefault.restarted(restarting, true)))
    check("while it still runs nothing ends", JSON.stringify(MakeDefault.restartStopped(restarting, true)), JSON.stringify(restarting))
    var late = after(CLAIM, 0, "", false)
    check("a restart that failed keeps the claim and says when file dialogs follow", look(BACHY, late),
          "true|false|File dialogs follow after xdg-desktop-portal restarts.|foreground|right")
    check("a release keeps its unticked box with the same line", look(NAUTILUS, after(RELEASE, 0, "", false)),
          "false|false|File dialogs follow after xdg-desktop-portal restarts.|foreground|right")
    check("the next run drops it", MakeDefault.started(late, RELEASE).outcome, "")

    check("partly: folders claimed, the chooser step skipped", look(BACHY, after(CLAIM, 0, skipped)),
          "true|false|File dialogs need the bachy package's portal files.|foreground|right")
    check("partly only while Bachy is still the answer", look(NAUTILUS, after(CLAIM, 0, skipped)), "false|false|||")
    check("partly keeps its own note when the restart fails, since its file dialogs never follow",
          look(BACHY, after(CLAIM, 0, skipped, false)), "true|false|File dialogs need the bachy package's portal files.|foreground|right")

    var failed = after(CLAIM, 1, "xdg-mime: warning from xdg-mime itself\nbachy: xdg-mime default exited 0 but inode/directory still resolves to org.gnome.Nautilus.desktop\n")
    check("failed: bachy's own first line without its prefix, in the error role, the box the re-read truth",
          look(NAUTILUS, failed), "false|false|xdg-mime default exited 0 but inode/directory still resolves to org.gnome.Nautilus.desktop|error|right")
    check("failed: the next press tries again", JSON.stringify(MakeDefault.press(NAUTILUS, failed)), JSON.stringify(CLAIM))
    check("a failed release keeps the box ticked when Bachy is still the answer", look(BACHY, after(RELEASE, 1, "bachy: a half failed\n")),
          "true|false|a half failed|error|right")
    check("a line bachy did not prefix is still better than nothing, the first that says anything",
          MakeDefault.errorLine("\n  \nsomething broke\nand then this\n", 1, true), "something broke")
    check("silence names the command and its status, a release", MakeDefault.errorLine("", 2, false), "bachy --default off exited 2")
    check("and a claim, blank lines being silence too", MakeDefault.errorLine("\n \n", 1, true), "bachy --default exited 1")
    check("a new run drops the last one's error", MakeDefault.started(failed, CLAIM).error + "|" + MakeDefault.started(failed, CLAIM).outcome, "|")

    var refused = MakeDefault.finished(claiming, 1, refusal, REREAD)
    var unpackaged = "false|true|Install a Bachy package to make it the default.|foreground|right"
    check("unpackaged from the refusal, before the re-read lands", look(NAUTILUS, refused), unpackaged)
    check("and after it", look(NAUTILUS, MakeDefault.settled(refused, REREAD)), unpackaged)
    check("an unpackaged press runs nothing", MakeDefault.press(NAUTILUS, MakeDefault.settled(refused, REREAD)), null)
    var probedOut = MakeDefault.probed(MakeDefault.idle(), false)
    check("unpackaged from the probe, before any press", look(NAUTILUS, probedOut), unpackaged)
    check("and an entry found later makes the row live again", look(NAUTILUS, MakeDefault.probed(probedOut, true)), "false|false|||")

    check("the probe walks src/userfile.rs data_file()'s ladder",
          MakeDefault.entryPaths({ HOME: "/home/gm", XDG_DATA_HOME: "", XDG_DATA_DIRS: "" }).join(","),
          "/home/gm/.local/share/applications/" + BACHY + ",/usr/local/share/applications/" + BACHY + ",/usr/share/applications/" + BACHY)
    check("a set data home and data dirs replace the defaults, and empty segments are skipped",
          MakeDefault.entryPaths({ HOME: "/home/gm", XDG_DATA_HOME: "/d/home", XDG_DATA_DIRS: "/d/a::/d/b" }).join(","),
          "/d/home/applications/" + BACHY + ",/d/a/applications/" + BACHY + ",/d/b/applications/" + BACHY)
    check("with no HOME there is no data home to look in", MakeDefault.entryPaths({ XDG_DATA_DIRS: "/d/a" }).join(","), "/d/a/applications/" + BACHY)
    check("each path is its own argument, never part of the script, which tests each one quoted and stops at the first",
          JSON.stringify(MakeDefault.probeCommand(["/a b/x.desktop", "$(y)"])),
          JSON.stringify(["sh", "-c", "for f; do [ -f \"$f\" ] && exit 0; done; exit 1", "sh", "/a b/x.desktop", "$(y)"]))
}

// pacman -Qi bachy-bin under LC_ALL=C on minipc, 2026-09-24, trimmed to the fields About reads; pacman -Si bachy-bin exits 1 there.
var BACHY_BIN_QI = "Name            : bachy-bin\nVersion         : 0.3.4-1\nPackager        : Unknown Packager\n"
    + "Build Date      : Wed Sep 23 12:40:50 2026\nInstall Script  : No\nValidated By    : None\n"

// Installed from is the kind src/update.rs derives from the same two pacman answers, so it and the Update Bachy row agree.
function runInstalled(check) {
    var update = source("src/update.rs")
    // Sample input: const AUR_PACKAGE: &str = "bachy-bin";
    function named(constant) { return (update.match(new RegExp("const " + constant + ": &str = \"([^\"]*)\";")) || [])[1] }
    check("the three package names are src/update.rs's own", [SettingsAbout.PACKAGES.opr, SettingsAbout.PACKAGES.aur, SettingsAbout.PACKAGES.git].join("|"),
          [named("OPR_PACKAGE"), named("AUR_PACKAGE"), named("GIT_PACKAGE")].join("|"))
    // Sample input: Kind::Aur => "aur",
    var words = (update.match(/Kind::[A-Za-z]+ => "[a-z]+"/g) || []).map(function (arm) { return arm.split("\"")[1] })
    check("one sentence for each kind word bachy --update check prints, and no other",
          Object.keys(SettingsAbout.SOURCES).sort().join("|"), words.sort().join("|"))

    var bin = SettingsAbout.packageFacts(BACHY_BIN_QI)
    check("bachy-bin's own -Qi reads as its package, its build date and no signature",
          [bin.package, bin.built, bin.signed].join("|"), "bachy-bin 0.3.4-1|Wed Sep 23 12:40:50 2026|false")
    check("so an AUR bachy-bin says so, where 0.3.4 read Local package", SettingsAbout.installedFrom("bachy-bin", bin.signed), "AUR, bachy-bin")
    check("the kind the Update Bachy row reads from the check line is the same one",
          answered("current aur 0.3.4-1 0.3.4-1").kind + "|" + SettingsAbout.installKind("bachy-bin", bin.signed), "aur|aur")
    check("OPR's signed bachy keeps the board's words", SettingsAbout.installedFrom("bachy", true), "Omarchy Package Repository")
    check("the same name unsigned is a local makepkg build", SettingsAbout.installedFrom("bachy", false), "Local package")
    check("bachy-git is the AUR's rolling build", SettingsAbout.installedFrom("bachy-git", false), "AUR, bachy-git")
    check("any other owner is somebody's own package, signed or not", SettingsAbout.installedFrom("bachy-custom", true), "Local package")
    check("no owner is a cargo build", SettingsAbout.installedFrom("", false), "Unpackaged candidate")
    check("Validated By is read as src/update.rs reads it",
          [SettingsAbout.packageFacts("Validated By    : SHA-256 Sum  Signature\n").signed,
           SettingsAbout.packageFacts("Validated By    : SHA-256 Sum\n").signed,
           SettingsAbout.packageFacts("Description     : Signature\nValidated By    : None\n").signed].join("|"), "true|false|false")
    check("a query that failed is an empty answer", JSON.stringify(SettingsAbout.packageFacts("")), '{"package":"","built":"","signed":false}')
    check("and About asks pacman -Si nothing, which cannot see an AUR package", source("ui/AboutFacts.qml").indexOf("\"-Si\""), -1)
}
