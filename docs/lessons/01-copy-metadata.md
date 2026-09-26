# Lesson 1: a file is more than its contents

Status: implemented on main after v0.1.0. The published v0.1.0 package remains unchanged.

Copying the words in a document does not automatically copy its modification date, permissions or extra attributes. Bachy's old copy loop copied bytes and restricted permissions, but left the destination with a new modification date and no user attributes.

## Before and after

| Example | v0.1.0 | Post-0.1.0 main |
|---|---|---|
| A document last modified in 2000 | Copy gets today's modification time | Copy keeps the observed source modification time |
| `user.bachy.lesson=notes` on a file or folder | Attribute lost | Attribute copied, including empty/binary values |
| Read-only file with a user attribute | Attribute lost | Owner-write enabled temporarily for metadata; final read-only mode restored |
| Mode 0664, process umask 0022 | Copy is 0644 | Still 0644; this milestone does not override umask |
| Metadata fails after a cross-filesystem move copies bytes | Metadata was not attempted | Reports failure, keeps source and partial destination; Undo can remove the unchanged partial copy |

## Follow the code

1. `src/backend/opsreq.rs::run_transfer_checked` starts a transfer and its progress-size scan. `one_item` calls the shared copy/move primitive.
2. `src/backend/copyfile.rs::copy_file_at` opens the source, captures metadata through that descriptor, creates a new destination, streams bytes, then calls `copymetadata::preserve` before recording the undo manifest.
3. `src/backend/copyfile.rs::copy_dir_at` applies directory metadata after all its children. Creating a child changes a folder's modification time, so restoring it before the children would be wrong.
4. `src/backend/copymetadata.rs::preserve` copies only `user.*` attributes, sets observed access/modification times, and restores `keep_mode(source_mode)` even if metadata work fails.
5. `src/backend/copyfile.rs::move_any` first tries a rename. Only EXDEV (different filesystems) falls back to copy followed by source removal. A copy error prevents that removal.

An open file descriptor refers to the opened object even if someone renames its path. Using `flistxattr`, `fgetxattr`, `fsetxattr`, descriptor time-setting and chmod prevents a later symlink/path swap from redirecting metadata to an unrelated file. The regression test deliberately swaps both paths.

Linux checks inode permission when reading/writing user attributes, even when an open descriptor exists. A read-only destination may therefore need temporary owner-write permission. Group/other permissions are not widened by this step. Attribute lists/values are bounded to 64 KiB and changing-size reads retry at most three times. See [Linux xattr semantics](https://man7.org/linux/man-pages/man7/xattr.7.html) and [fgetxattr](https://man7.org/linux/man-pages/man2/fgetxattr.2.html).

## Exact scope and limits

- Regular files and directories: modification time, observed access time, `user.*` xattrs. Duplicate and cross-filesystem move use the same primitives. Same-filesystem rename already retains inode metadata.
- Access time is captured at each item's open, **not at the moment the user clicks Copy**. Bachy's concurrent size scan (or any other reader) may have advanced directory access time first. The real transfer test observed this. No source timestamps are rewritten to conceal it.
- Attribute values are read after byte copying. Concurrent source edits are not an atomic snapshot and data copying has no checksum-verification feature.
- No ownership, ACL, `security.*`, `trusted.*`, `system.*`, creation/ctime, special-bit or symlink/special-node metadata preservation. Existing symlinks remain links and their targets are not followed for metadata.
- Modes remain source permissions intersected with process umask, without setuid/setgid/sticky. Exact permission cloning is a separate policy decision. Destination default ACL inheritance is outside this change.
- A source without xattr support is treated as having none. If source user attributes exist but the destination cannot store them, or time/mode restoration fails, the item fails visibly; copied bytes alone do not count as success.
- Metadata failures leave partial results on disk and journal them where possible; they are not rollback transactions. Undo retains existing identity/manifest checks and refuses changed results. A chmod failure can leave the temporary owner-write bit in place and is reported as failure.
- Tested on local tmpfs fixtures on distinct mounts, not every filesystem or remote mount. Timestamp precision and attribute availability are filesystem-dependent; successful syscalls can round timestamps.

## Evidence

`src/backend/copymetadata_tests.rs` contains 11 tests covering nanosecond timestamps, empty/binary/non-UTF-8 user attribute names, directories finalized after children, readonly permissions, umask/special bits, source/destination path swaps, metadata failures and partial recovery, ACL exclusion, manifest timestamp ordering, bounded size races and syscall errors. Permission-denial tests skip when running as root; this recorded run used uid 1000.

`bash tests/copy-metadata.sh` uses marked guarded fixtures under `/tmp` and `/dev/shm`, requires different filesystem devices, and talks to the real debug backend. It verifies tree modification times and user attributes for copy and EXDEV move, notes the directory access-time limit, then stops only its own process briefly to make the source unreadable during a 512 MiB sparse-file transfer. It verifies visible failure, retained source/partial destination, restored read-only mode and successful Undo cleanup. This is backend integration, not mouse/UI evidence.

Run `cargo build --locked`, `cargo test --locked copymetadata` and `bash tests/copy-metadata.sh`. Do not disable fixture guards or point these tests at personal documents.

## Safe hands-on exercise

Read `readonly_file_keeps_times_empty_binary_and_non_utf8_user_attributes` first. Predict which fields would survive a byte-only copy, then run the targeted test. Change only the test fixture's timestamp and attribute value, rerun, and revert that test-only edit afterward. Follow `preserve` in order: names → values → times → final permissions. The integration script provides a disposable working example without involving your own files.

The first wider `tests/ops.sh` attempt failed its two GIO Trash scenarios in the existing session; rename, duplicate, copy/move, conflict refusal and their Undo checks passed. That environment failure is not included as a passing suite and is being investigated separately in the feature audit.
