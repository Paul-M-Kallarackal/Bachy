# Contributing

Bachy is an experimental fork. Start with [ROADMAP.md](ROADMAP.md), [LIMITATIONS.md](LIMITATIONS.md) and [UPSTREAM.md](UPSTREAM.md). Keep fixes focused and distinguish Bachy behavior from inherited Flea assumptions.

Before changing behavior, read the relevant repository instructions in AGENTS.md. It retains extensive upstream engineering notes, including viewport-scoped row work, lazy UI loading and disposable-test requirements. Do not copy upstream benchmark claims into Bachy documentation without reproducing them.

For an ordinary change, run the relevant Rust or JavaScript tests and explain what was actually verified. The core commands are in README.md; native and integration prerequisites are in docs/BACHY-VERIFICATION.md. Never run file-operation tests against personal files, disable their sandbox guards, or claim the complete test runner passed when only selected suites ran.

Bug reports are most useful with the Bachy commit, distribution, Hyprland/Qt/Quickshell versions, exact steps, expected/actual results and a minimal disposable example. For startup reports, distinguish fresh boot, first launch after idle and repeated launches. Remove private filenames and credentials from logs before posting.
