# Dependency and startup optimization audit

Measured 27 September 2026. This change makes QtQuick.Pdf optional in the graphical interface. The original v0.1.0 release asset remains unchanged; the source recipe is now 0.1.0-3.

## Implemented

`PKGBUILD` moves qt6-webengine from depends to optdepends. `OptionalPdf.qml` compiles the PDF-only component on demand and loads it through a Loader only when available. Both PreviewColumn and PdfViewer use that boundary. No PDF probe runs while browsing ordinary files.

Missing QtQuick.Pdf displays “PDF preview unavailable” with the Arch package name and restart guidance. Other component errors get a distinct startup-failure message; corrupt documents retain the file-read failure. A shared fallback offers keyboard/pointer external opening through Bachy's existing opener. No package installation is performed by the UI.

A rendering regression test caught an important implementation detail: PreviewPdf writes its own page property when clamping the newly opened document, so a permanent binding from the wrapper was overwritten. The wrapper now forwards requested page changes explicitly. Tests check the displayed page, not only the requested page number.

## Install cost

Official Arch core/extra sync snapshots from September 23, resolved with pacman against a private empty local package database. Baseline: base + hyprland + quickshell, default providers, hard dependencies only. Unique installed sizes are summed once and the baseline is subtracted. No system packages were installed/removed and no system database was refreshed.

| Scenario | Added installed size |
|---|---:|
| Before PDF fix | 838.16 MiB |
| After PDF fix | 552.18 MiB |
| PDF-related saving | **285.98 MiB** |
| Dolphin on the same baseline | 659.07 MiB |

Bachy's own payload is excluded; Dolphin's own package is included. These are install-graph figures, not feature-equivalent performance comparisons. They differ from the commenter's absolute totals because the exact baseline/provider/snapshot needs to match. The approximately 286 MiB saving agrees with the proposed change.

Further candidates, measured independently from the new 552.18 MiB baseline:

| Candidate | Potential saving | Required work before shipping |
|---|---:|---|
| Optional QtMultimedia | 171.24 MiB | Graceful fallback in both media surfaces, playback/control tests with module present and absent; preserve external opening. Shared FFmpeg dependencies make this much more valuable after optional PDF. |
| System/configurable font instead of mandatory noto-fonts | 106.81 MiB | Preserve readable monospace metrics, Unicode coverage, file-name elision and layout. Default currently explicitly requests Noto Sans Mono. |
| Optional SMB backend | 32.28 MiB | Capability detection and useful missing-backend guidance; validate real SMB separately. |
| Optional phone/camera backends | 31.54 MiB | Discovery/unlock/mount messaging and physical-device checks. Keep core GVFS for local behavior. |
| Optional extended Qt image formats | 2.92 MiB | Weigh the small saving against poorer phone-image previews. |

Do not add the independent savings blindly. Python is directly required by desktop integration and also retained through SMB/media dependencies; deleting its direct depends entry is not a reliable saving. Bubblewrap/prlimit protect parsing and extraction and are not size-cut candidates. TUI mpv/poppler and LocalSend optional dependency descriptions also need a separate completeness review.

## Startup measurement

Ten interleaved native Hyprland launches, five per version, over 1,000 disposable text files. Each run had separate empty application config/state/cache directories; both variants used the same release binary, fixed Intel Vulkan and identical unrelated working-tree UI edits. The baseline copied the old PDF files; the candidate used this change. Polling measured the mapped window and first populated row. This is **not cold-boot/cold-disk evidence**: OS page cache was not dropped, and the fixed renderer bypasses the source launcher's automatic GPU policy. Build/other desktop activity can also add noise.

| Median | Before | After |
|---|---:|---:|
| Window mapped | 277.60 ms | 275.99 ms |
| First row available | 318.98 ms | 326.94 ms |
| Process-tree PSS 300 ms later | 96.43 MiB | 96.68 MiB |

There is no demonstrated startup speedup or material regression in this small sample. Optional PDF mainly improves download/disk/update cost because PDF was already lazy-loaded. The timing pass preceded the page-forwarding fix, which changes only the active-PDF path; ordinary-folder startup is unchanged by that correction.

## Speed and memory priorities

1. **Packaged hybrid-GPU startup.** The source `run-bachy` wrapper selects Intel before the foreground launch and performs NVIDIA readiness work in the background. PKGBUILD installs the Rust binary directly, so it does not carry that wrapper policy. Moving the tested policy into the packaged launcher is a higher-priority first-launch target than further PDF laziness. Preserve explicit GPU overrides, the operator's Intel-first preference and external-app environment cleanup. No new timing claim is made for this unimplemented change.
2. **Retained view lifetime.** `Pane.qml` keeps grid/columns loaders active after their first visit, and the list view remains allocated while hidden. In one native 10,000-file exploration, process-tree PSS went from 95.45 MiB initially to 101.83 MiB after grid, 111.41 MiB after columns and 112.03 MiB after returning to list. The 16.58 MiB retained difference includes QML, allocator and backend caches; it is not an isolated measurement of unnecessary hidden work. Profile model updates and idle CPU before unloading anything; preserve cursor, selection, scroll and focus when switching views.
3. **Font resolution and first QML compilation.** Font packaging is a proven size target; font scanning/compilation is only a speed hypothesis until profiled with a controlled empty cache and locale. Keep font metrics stable and avoid blocking capability probes on startup.
4. **Preserve existing deferred work.** PDF/media loading, settings/dialog loaders, background Trash/update work and viewport-scoped metadata already avoid startup work. Avoid “optimizations” that eagerly preload all features or merely move costs to login when first use is the priority.

## Verification

- New `tests/pdf-optional.sh`: real preview column and Quick Look, installed/missing/broken component modes; actual second-page render; corrupt-PDF distinction; keyboard action through the existing key handler; exact external-open argv against a stub; close/unload; both browser and chooser start with QtQuick.Pdf hidden by a child-only bwrap mount.
- `tests/pdf-turn.sh`: 12 passing render/frame checks after the page-forwarding fix.
- `tests/pdf-first.sh`: 3 checks passed.
- `tests/shellload.sh`: 5 checks passed.
- JavaScript: 3,967 checks passed.
- Rust: 863 debug and 863 release tests passed; no Rust implementation changed.
- Working-tree 0.1.0-2 archive built using `makepkg -f --nodeps --nocheck` because this development host uses an extracted Qt runtime; suites ran separately. Package assertions verify optional PDF metadata and required helpers. This is not a clean-machine installation or a newly published release.
- Paper file: https://app.paper.design/file/01M3DNAMX5PQERN25GEWE1PN05/p-1-0, “PDF preview — optional support”. Reviewed both fallback layouts; readable hierarchy, wrapping and buttons fit the column and Quick Look. Offscreen implementation captures confirm the corresponding state.

Next release gates should keep two runtime configurations (minimal and full-feature), record package versions/provider choices for size comparisons, and measure first populated frame separately from window mapping. Keep warm relaunch results separate from first application-cache and cold-boot measurements.

## Follow-up: optional media, fonts and packaged startup (0.1.0-3)

The next dependency pass is implemented:

- `qt6-multimedia` is optional. `OptionalMedia.qml` isolates its import and preserves real play/pause/seek behavior when installed. With an absent or broken component, both preview surfaces explain the problem and offer external opening. Selection alone still constructs no player. Corrupt media is a playback error, not an installation prompt.
- The PDF and media fallbacks share `PreviewUnavailable.qml`. No capability probe or package installation runs during ordinary browsing.
- `noto-fonts` is optional. The default font is the installed `monospace` mapping; `BACHY_FONT` still wins. On this machine that mapping is Noto Sans Mono. A private Fontconfig configuration also tested DejaVu Sans Mono without Noto. Character coverage depends on installed fonts.
- The package installs a public `/usr/bin/bachy` launcher and the Rust backend at `/usr/lib/bachy/bachy`. It shares `tools/bachy-gpu-policy` with `run-bachy`. CLI helpers bypass the graphics policy; graphical startup keeps Intel first, background NVIDIA verification, awake-device checks, failure cooldown and explicit overrides. The backend still avoids wrapper overhead for its own CLI helpers.
- The approved logo is unchanged. Its Qt Quick Shapes component now loads only when the mark is visible, rather than importing and constructing the hidden drawing on every populated-folder launch.

Re-resolving the complete dependency graph with the same baseline/snapshots gives:

| Source recipe | Added hard dependencies |
|---|---:|
| Original | 838.16 MiB |
| Optional PDF | 552.18 MiB |
| Optional PDF + media | 380.94 MiB |
| Optional PDF + media + system font | **274.13 MiB** |
| Cumulative reduction | **564.03 MiB (67.3%)** |

These are graph estimates, not bytes removed from an existing installation. A dependency already installed for another application is shared; making it optional does not uninstall it. The original v0.1.0 release asset still has its original dependencies. The current working-tree archive is 0.1.0-3.

The remaining independent size candidates now measure 32.73 MiB for SMB, 44.39 MiB for phone/camera backends, and 2.92 MiB for extended image formats. They remain required in this pass: removing them needs useful capability/discovery messaging and feature-specific validation. Core GVFS, Python desktop-integration helpers, and the parser/extraction sandbox are retained. The earlier candidate table records the earlier baseline; its marginal savings should not be added to this table.

### First-launch experiments

Each experiment used ten interleaved native Hyprland launches over 1,000 files, separate empty app caches/configurations, Intel Vulkan, and the same release binary. OS cache was not cleared. Window mapping and an IPC-visible first row are different observations; neither proves the first usable rendered frame. Desktop activity introduces noise. These runs bypass automatic GPU selection, so they cannot measure sleeping-NVIDIA wake-up savings.

| Experiment | Window median before → after | First-row median before → after | Decision |
|---|---:|---:|---|
| Delay device/mount/Trash queries 350 ms | 308.81 → 312.80 ms | 353.41 → 350.39 ms | Rejected: no clear benefit; delayed sidebar data |
| Disable QML cache writes | 306.17 → 291.45 ms | 348.23 → 325.54 ms | Rejected: gives up persistent compilation caching |
| Bypass qt6ct platform theme | 313.08 → 293.93 ms | 349.52 → 341.23 ms | Rejected: small/noisy result; desktop-theme behavior needs validation |
| Defer hidden logo drawing, final implementation | 304.40 → 314.93 ms | 345.60 → 338.37 ms | Kept to avoid hidden drawing work; no demonstrated overall launch speedup |

An earlier logo prototype measured a roughly 22 ms first-row improvement, but the final repeat did not reproduce a robust gain. Do not advertise that prototype number. Ahead-of-time QML compilation remains a separate build/runtime project: the current Arch runtime lacks qmlcachegen and Qt recommends integrating compilation through its module build system. See [Qt's cache documentation](https://doc.qt.io/qt-6/qmldiskcache.html) and [qmlcachegen documentation](https://doc.qt.io/qt-6/qtqml-tool-qmlcachegen.html). No fragile copied cache or preloaded resident process was shipped.

### Follow-up verification

- `tests/media-optional.sh`: 12 installed/missing/broken × column/Quick Look × audio/video combinations. Tests real silent media decoding, pause/seek, corrupt-file distinction, lazy creation, exact external-open arguments and teardown. Narrow 220-pixel columns scroll the fallback so keyboard focus reveals the external-open action.
- `tests/pdf-optional.sh`: all six surface/runtime combinations and both entry points passed after the shared fallback refactor.
- Minimal runtime smoke: both browser and chooser start with QtQuick.Pdf and QtMultimedia masked in the child mount namespace and a font configuration excluding Noto. No host package changes.
- `tests/gpu-policy.sh`: synthetic Intel/NVIDIA/mixed connectors test first launch, readiness, suspended fallback, cooldown, overrides and CLI exclusion without touching real GPUs.
- Offscreen captures confirm both media fallback layouts and unchanged logo rendering at 240, 64, 32, 24 and 16 pixels, plus the empty-folder state.
- JavaScript checks, file budgets and empty-state checks passed. No Rust implementation changed; the prior 863 debug/863 release results still apply to the unchanged backend.
- Package metadata checks enforce optional PDF/media/fonts and compare the installed launcher scripts with source. The archive is built with `--nodeps --nocheck` on the extracted development runtime; independent checks run separately. This is not a clean-machine install or a new public release asset.
- Paper: the same project file now includes “Media preview — optional support” beside the PDF fallback. The dependency changes preserve existing screens; only the missing-media recovery state is new.
