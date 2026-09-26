# Verification status — Bachy 0.1.0

Last local core run: 26 September 2026, CachyOS/Hyprland. Results below distinguish core checks, selected integration checks and unverified behavior. They are not a claim of complete Thunar/Nautilus/Dolphin parity.

## Post-0.1.0 copy-metadata milestone

The source change documented in [Lesson 1](lessons/01-copy-metadata.md) is not in the published v0.1.0 package. Debug and release Rust suites each passed **863 tests**, including **11 new metadata regressions**, and both profiles built. The real-backend `tests/copy-metadata.sh` passed cross-filesystem tree copy/move and injected metadata-failure/source-retention/Undo checks on distinct tmpfs mounts as uid 1000. Modification times and user attributes survived; directory access time can already have advanced during the concurrent size scan. This is not an atomic pre-transfer timestamp snapshot or evidence for every destination filesystem.

A fresh `tests/ops.sh` run passed rename, duplicate, copy/move, no-overwrite and their Undo scenarios, but failed the GIO Trash scenarios in the current test environment. The suite is **not counted as passing**; the feature audit will record the isolated-session rerun separately.

## Comprehensive feature audit

See the [26 September feature audit](BACHY-FEATURE-AUDIT.md) for current GUI/TUI distinctions, native and PTY evidence, corrected test drivers and remaining external prerequisites. Passing individual suites is not certification of every feature or of the full inherited runner.

## Core checks

- `cargo test --release --locked`: **852 passed, 0 failed** on the publication-preparation run.
- `tests/js.sh`: **3,967 checks, 0 failed** (3,954 main, 4 timezone, 9 DST).
- `tests/keymap-gen.sh`: duplicate-chord, Qt key-name, pointer legend and generated-keymap consistency checks passed.
- Release and debug builds passed during port verification; the release binary was rebuilt after adding the internal GPU probe.
- Bash syntax checks and `git diff --check` passed.

## Selected integration checks

During the local port, disposable fixtures and isolated HOME/XDG/private-bus environments were used for copy, move, rename, duplicate, trash, conflicts and undo (`tests/ops.sh`); archive and UI-state writes; CLI modes; FileManager1 routing and encoded paths; portal request handling with a stub picker; and stubbed network/authentication flows. Taildrop's argv/completion/error behavior was tested with a Tailscale stub, not a real peer.

Offscreen Quickshell rendered the browser and About settings. A locally built package was extracted, and its actual UI/binary launched with correct fixture rows and local components. The public v0.1.0 package was subsequently built from the pre-metadata source, its 201 packaged UI files compared, desktop entry validated, isolated pacman installation checked and its packaged binary/UI launched offscreen. The published download was fetched and its SHA256 verified. This package does not include the post-0.1.0 metadata change or the source-launcher hybrid policy.

Real Hyprland checks subsequently verified:

- Source-launcher windows and the existing file-manager launch command.
- GIO default-folder routing and FileManager1 ShowItems.
- Centered floating behavior without resizing the current tiled window.
- HTML and PDF opening through the actual UI's Open action, with the configured browser activating across workspaces after the compositor activation setting was enabled.
- Intel and NVIDIA rendering, including an inspected NVIDIA-rendered window and Qt device logs.
- Background GPU-check success/failure/wrong-vendor/lock behavior, plus 24 Vulkan/GUI unit tests.

Physical mouse double-click delivery was not separately automated in the activation check; Enter used the same Open action. Real file-handler tests prove the tested handler, not every desktop application.

## Startup measurements

On one Intel/RTX 5070 laptop, the original automatic launch took 2,801 ms to first rows. A launcher-only probe took 2,546 ms while NVIDIA moved from suspended to active. The Intel-only probe took 9 ms.

With the hybrid source launcher, the first Intel listing was ready in 252 ms, background NVIDIA readiness arrived at 3,058 ms, and a subsequent NVIDIA listing was ready in 472 ms. A further test with cached readiness and NVIDIA asleep chose Intel in 272 ms, followed by NVIDIA in 467 ms.

These are idle-GPU observations with local caches, not fresh-boot or cold-disk benchmarks. They measure listing readiness via IPC and window mapping, not instrumented input-to-photon latency. External-monitor and alternative-GPU setups remain unverified. The package's binary entry point does not currently include this source-launcher policy.

## Known failing or missing coverage

The inherited `tests/run-all.sh` is **not green**. An initial run reported 24 failures out of 35 suites, largely involving missing fixture roots/media, `inotifywait`, legacy Omarchy tooling and environment-specific command resolution. Several suites passed individually afterward; the entire runner was not rerun to completion and is not advertised as passing.

The later feature audit passed media-fixture thumbnail/protocol checks and replaced the timing-sensitive UI-state assertion with a deterministic interruption test. Comprehensive pointer/drag behavior, real chooser compatibility, accessibility, physical devices and live network endpoints remain outside that evidence. Historical Flea benchmarks and screenshots are not Bachy measurements.

## Reproducing

With runtime and development dependencies installed:

```sh
cargo build --locked
cargo test --release --locked
bash tests/js.sh
bash tests/keymap-gen.sh
```

Integration tests require `BACHY_FIXTURE_ROOT` to name a writable disposable directory outside HOME. Keep the sandbox guard enabled. GIO Trash requires a session bus; use a private bus and isolated HOME/XDG environment for tests. Some native drivers still depend on Omarchy-specific test tooling even though the application no longer imports the Omarchy shell. Read individual prerequisites before running a suite.

The GitHub workflow runs a narrower core Rust test/build job. Its current status is shown by GitHub; a local passing run is not evidence that remote CI passed.
