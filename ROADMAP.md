# Roadmap

Ordered by impact on everyday use. Unchecked items are plans, not shipped functionality or release-date promises. File-operation correctness comes before additional visual effects.

## 1. Reliable daily file operations

- [ ] System clipboard interoperability: cut/copy/paste between Bachy windows and other managers, including URI lists, ownership changes and move semantics.
- [x] On post-0.1.0 main: preserve modification timestamps and user extended attributes for regular files/directories; report metadata failures and test copy/move across filesystems.
- [ ] Extend copy fidelity to ACLs, ownership and an explicit exact-permission policy; evaluate a pre-transfer access-time snapshot and additional filesystem types.
- [ ] Recursive directory merge with clear conflict handling, cancellation and meaningful undo boundaries.
- [ ] Better operation errors and recovery for partial copies, full disks, disconnected mounts and permission failures.
- [ ] Transfer queue and checksum-verification option; evaluate pause/resume separately.
- [ ] Proper support for non-UTF-8 Linux filenames throughout the protocol and UI.

## 2. Predictably fast first launch

- [x] Identify the synchronous discrete-GPU wake-up cost on the development laptop.
- [x] Source-launcher Intel-first path with a delayed NVIDIA check, bounded timeout, session lock and fallback after GPU idle.
- [ ] Make renderer preference configurable; offer Intel-only, automatic and hybrid policies without changing code.
- [x] Use the same startup policy from the package, source launcher, chooser and desktop entry (source revision 0.1.0-3).
- [ ] Instrument startup stages: command receipt, Qt/QML initialization, window mapping, first rows and first usable input.
- [ ] Measure fresh-install/reboot-cold and idle-GPU cases; report medians and slower-tail results alongside memory usage.
- [ ] Profile QML creation and evaluate ahead-of-time compilation; defer any remaining optional startup work only when measurements demonstrate a benefit.
- [ ] Verify external-monitor, mixed-GPU, ARM and non-NVIDIA configurations.

A resident process or login preloading is an optional future experiment, not a substitute for measuring true first-launch cost. NVIDIA is not assumed faster: the measured subsequent NVIDIA launch was slower than Intel on the development laptop.

## 3. Everyday parity

- [ ] GUI bulk rename with preview, numbering and pattern replacement (external-editor batch rename already exists in the TUI).
- [ ] Document templates, symlink creation, invert selection and wildcard selection.
- [ ] Multi-file properties, recursive permissions and group changes.
- [ ] Restore tab sessions; reorder, detach and reopen tabs.
- [ ] Per-folder view preferences, richer columns and shortcut customization.
- [ ] Local bookmark import, Recent files and starred items.
- [ ] Optional indexed content search with explicit privacy/storage controls.
- [ ] Better archive controls and dependency diagnostics for network/device actions.

## 4. Packaging and confidence

- [ ] Reproducible clean-machine CachyOS/Arch build, install, upgrade and removal tests.
- [ ] Port remaining Omarchy-specific test drivers; make the full supported test runner green.
- [ ] Expand CI beyond core Rust checks to JavaScript, packaging and native-session integration where practical.
- [ ] Validate file-chooser routing, multi-item Show in folder and FileManager1 Properties.
- [ ] Test real network shares, phone backends, removable devices and cross-application drag-and-drop.
- [ ] Accessibility audit with keyboard-only navigation, AT-SPI/Orca and high-contrast themes; add localization infrastructure.
- [x] Integrate the abstract fugue emblem into the repository, packaged SVG and native QML marks.

## Already established

- [x] Standalone Bachy identity and local QML components, without Omarchy runtime imports.
- [x] Working browser, core file operations, source launcher and initial Arch package recipe.
- [x] Documented Hyprland shortcut, floating-window behavior and cross-workspace application activation.
- [x] Public features, limitations, verification and upstream provenance documentation.

## Dependency and startup follow-up

- [x] Optional graphical PDF support with missing-module recovery in both preview views.
- [x] Use the installed monospace font; keep Noto optional and explicit font overrides.
- [x] Make multimedia optional with present/missing/broken/corrupt playback tests; measure shared dependencies together.
- [ ] Separate optional phone/camera/SMB backends from core browsing after testing capability discovery.
- [ ] Measure retained view work after grid/column visits; distinguish useful caches from active hidden views before changing lifetime.
- [x] Carry the source launcher’s tested hybrid-GPU policy into packaged launches.
- [ ] Record dependency closure and fresh application-cache startup baselines for each release.

See [dependency and startup audit](docs/DEPENDENCY-AND-STARTUP-AUDIT.md) for measurements and limits.
