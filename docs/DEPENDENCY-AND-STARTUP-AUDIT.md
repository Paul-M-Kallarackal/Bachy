# Optional PDF support and the next optimization targets

Measured 27 September 2026. This change makes QtQuick.Pdf optional in the graphical interface. The original v0.1.0 release asset remains unchanged; the source recipe is now 0.1.0-2.

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
