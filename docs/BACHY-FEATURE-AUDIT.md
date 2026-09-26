# Bachy feature audit — 26 September 2026

This audit uses application source `8f20c70fade8b540f43599c745a575a78a4ee052`, including the new copy-metadata milestone. Subsequent changes in this audit update test drivers and documentation only. The published v0.1.0 package remains unchanged and does not contain that metadata change.

## Evidence and its limits

- Debug and release Rust suites: **863 passed each**, including 11 copy-metadata tests. These are shared backend/TUI unit and fixture tests; they do not prove every GUI interaction or live integration.
- JavaScript: **3,967 checks passed** (3,954 general, 4 timezone, 9 DST).
- Real-backend copy-metadata integration: tree copy and EXDEV move preserve modification times and user attributes. An injected metadata failure retains the source, restores destination mode and allows Undo to remove the partial copy. Directory access time is observed at open and can already have advanced during size scanning.
- Native GUI: **13 targeted keyboard scenarios passed** on Hyprland 0.56.2, using the owned window's PID/address and read-only Quickshell IPC. Listing, grid/columns mode switching, tab creation/close, select-all, hidden toggle, path-editor opening, menu opening, settings opening, exact text preview, folder enter/parent, new folder and Undo were exercised. This does not prove pointer/range/drag behavior, path completion, every settings control or every action within those views.
- TUI: **4 pseudo-terminal scenarios passed**: listing/selection, external-editor two-file rename with filesystem/content verification, text preview and opening the key sheet. This is actual `--tui` execution, not native terminal graphics or audio output evidence.
- Thirty of 31 inspected shell suites passed in the final system-tool configuration (the archive suite explicitly skips optional 7z); `ops.sh` remains failing for the stated Trash prerequisite. The separate copy-metadata integration also passed. This is not a run of the full inherited runner.
- Protocol, archives/conversion, thumbnails in both worker/exec modes, media probing, FileManager1, portal request handling, CLI modes, state writes, offscreen loading/settings/focus and network process-control scenarios passed their inspected individual suites. FileManager1 uses stub launched windows; the portal uses a stub chooser; network and provider stubs do not establish a live transfer to a device/account/server.
- Package checks passed against the **existing v0.1.0 archive**. This validates its declared dependencies and checked packaged helpers/hooks, not a new binary release or a clean-machine installation of this source revision.

## Environment corrections made during the audit

The initial shell found a user Python wrapper without GObject. Using system Python corrected portal/FileManager1 failures. Missing media input initially caused protocol thumbnail failures; synthetic JPEG/video/text fixtures fixed the functional run. Those fixtures are on tmpfs and are explicitly not cold-cache/performance evidence.

Expect, inotify-tools, zip and 7zip were downloaded from the official Arch package endpoints and extracted into the audit workspace without modifying system packages. Extracted 7zip is not visible inside the archive sandbox, as detailed below. The password test can now use `BACHY_EXPECT_BIN` and reports a missing interpreter clearly. Its fake-password trust-warning, storage, split-prompt and redaction cases passed.

The chooser cancellation harness now includes Backend.qml’s real JavaScript imports. The GVFS fixture check respects an isolated XDG runtime instead of assuming `/run/user/<uid>`. PDF and preview test imports now use Bachy's standalone `ui/boot/Commons` and `ui/boot/Ui`. The package test initializes the makepkg variables it reads and compares its embedded helper against the current source, instead of a stale pre-port frozen digest. The package's actual helper already matched the source; the release was not changed to make the check pass. Final package validation used the downloaded public archive with SHA256 `b224a0b175532a676cc5b07a7784fb7c10ca77fbbec2e2212aaf8a2d9055e424`.

The UI-state random-kill stress loop sometimes killed processes before startup or after the write, never inside it. It remains as stress evidence, but its timing is no longer the proof of interruption safety. A test-only `rename` barrier pauses the owned writer after syncing its temporary file; the test kills that PID, proves the new state was fully staged, and verifies the original state is unchanged. This makes the critical assertion deterministic without changing production code.

## Remaining gaps

The extra archive run with locally extracted 7zip failed: the backend advertised the tool found on PATH, but its sandbox clears the environment and exposes `/usr`, not the workspace runtime. A focused real-backend probe reported `bwrap: execvp 7z: No such file or directory`. This is a tool-discovery limitation for non-system installations, not a passing 7z round trip. The final system-tool run passed tar.zst, ZIP and RAR (through the system reader), explicitly skipping optional 7z. Both the failed extended run and the successful system-tool run are retained in the delivered evidence. Testing 7z requires a tool installation visible inside the existing sandbox; the sandbox was not weakened and no system package was installed.

`tests/ops.sh` still fails its GIO Trash scenarios on the current `/tmp` fixtures: GIO refuses trashing on a system internal mount. Other operation scenarios in that suite pass. The guard requires destructive fixtures outside HOME; `/home` is root-owned and no passwordless privilege is available to create a sibling fixture. Keep this environment failure visible instead of disabling the guard or claiming the full suite is green.

Live SMB/SFTP/FTPS/WebDAV/NFS endpoints, account/peer sharing, phones, removable devices, accessibility/AT-SPI and cross-application pointer drag require separate approved resources or user interaction. Native TUI foot/kitty media/graphics coverage remains incomplete; the inherited full native driver requires `omarchy-drive`, `xdg-terminal-exec`, both configured terminals and media tools. PTY checks are not equivalent to that driver.

The full inherited `tests/run-all.sh` has not been certified green. Individual suite results must not be represented as a pass of that full runner.

## Code and documentation discoveries

The graphical interface renames one item at a time, but `src/tui/batch.rs::Batch::edit` implements multi-selection external-editor rename in the terminal. It validates names and object identities, then applies sequential renames; it is not an atomic batch transaction or a graphical naming-template editor. The feature and limitation pages now make that distinction.

LocalSend through `localsend-cli` and retained `bachy shelf` CLI/state helpers also exist. Omarchy bar installation is removed; the remaining commands do not imply that a shelf bar is installed. Documentation can lag behind executable code, so read the source and run a scoped example before relying on a broad feature claim.
