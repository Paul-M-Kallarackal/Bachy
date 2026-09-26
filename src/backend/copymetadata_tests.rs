use super::*;
use crate::backend::{copyfile, copymanifest, testdir::TestDir};
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::Path;
use std::sync::atomic::AtomicBool;
use std::time::{Duration, UNIX_EPOCH};

fn tagged(path: &Path, name: &[u8], bytes: &[u8]) {
    set(&File::open(path).unwrap(), &CString::new(name).unwrap(), bytes).unwrap();
}

fn attr(path: &Path, name: &[u8]) -> Vec<u8> {
    value(&File::open(path).unwrap(), &CString::new(name).unwrap()).unwrap()
}

fn dated(path: &Path, offset: u64) -> Metadata {
    File::open(path).unwrap().set_times(FileTimes::new()
        .set_accessed(UNIX_EPOCH + Duration::new(900_000_000 + offset, 123_456_789))
        .set_modified(UNIX_EPOCH + Duration::new(950_000_000 + offset, 987_654_321))).unwrap();
    path.metadata().unwrap()
}

fn same_times(path: &Path, expected: &Metadata) {
    let actual = path.metadata().unwrap();
    assert_eq!(actual.accessed().unwrap(), expected.accessed().unwrap(), "{} access time", path.display());
    assert_eq!(actual.modified().unwrap(), expected.modified().unwrap(), "{} modification time", path.display());
}

fn copy(src: &Path, dst: &Path) {
    let flag = AtomicBool::new(false);
    let mut sink = |_: u64, _: u64| {};
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None, manifest: None };
    copyfile::copy_any(src, dst, &mut p).unwrap();
    assert!(p.partial.is_none());
}

// fsetxattr checks mode even on a held writable fd. A read-only source's copy must
// retain attributes without becoming permanently owner-writable.
#[test]
fn readonly_file_keeps_times_empty_binary_and_non_utf8_user_attributes() {
    let d = TestDir::new("metadata-readonly");
    let src = d.file("source", "contents");
    tagged(&src, b"user.empty", b"");
    tagged(&src, b"user.binary", &[0, 255, 1, 0, 128]);
    tagged(&src, b"user.raw-\xff", b"raw name");
    let before = dated(&src, 0);
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o400)).unwrap();
    let dst = d.join("copy");
    copy(&src, &dst);
    same_times(&dst, &before); // Check before reading content can advance atime.
    assert_eq!(attr(&dst, b"user.empty"), b"");
    assert_eq!(attr(&dst, b"user.binary"), [0, 255, 1, 0, 128]);
    assert_eq!(attr(&dst, b"user.raw-\xff"), b"raw name");
    assert_eq!(dst.metadata().unwrap().mode() & 0o7777, copyfile::keep_mode(0o400));
    assert_eq!(std::fs::read(&dst).unwrap(), b"contents");
}

#[test]
fn directories_finish_metadata_after_children_and_keep_symlinks_unfollowed() {
    let d = TestDir::new("metadata-tree");
    let src = d.dir("source");
    let sub = d.dir("source/sub");
    let child = d.file("source/sub/file", "child");
    let outside = d.file("outside", "untouched");
    tagged(&src, b"user.tag", b"root");
    tagged(&sub, b"user.tag", b"sub");
    tagged(&child, b"user.tag", b"child");
    tagged(&outside, b"user.tag", b"outside");
    std::os::unix::fs::symlink(&outside, src.join("link")).unwrap();
    let root_time = dated(&src, 1);
    let sub_time = dated(&sub, 2);
    let file_time = dated(&child, 3);
    let outside_time = dated(&outside, 4);
    std::fs::set_permissions(&sub, std::fs::Permissions::from_mode(0o500)).unwrap();
    let dst = d.join("copy");
    copy(&src, &dst);
    same_times(&dst, &root_time);
    same_times(&dst.join("sub"), &sub_time);
    same_times(&dst.join("sub/file"), &file_time);
    same_times(&outside, &outside_time);
    assert_eq!(attr(&dst, b"user.tag"), b"root");
    assert_eq!(attr(&dst.join("sub"), b"user.tag"), b"sub");
    assert_eq!(attr(&dst.join("sub/file"), b"user.tag"), b"child");
    assert_eq!(attr(&outside, b"user.tag"), b"outside");
    assert_eq!(dst.join("sub").metadata().unwrap().mode() & 0o7777, copyfile::keep_mode(0o500));
    assert!(dst.join("link").symlink_metadata().unwrap().is_symlink());
    assert_eq!(std::fs::read_link(dst.join("link")).unwrap(), outside);
}

#[test]
fn copied_modes_keep_umask_restrictions_and_drop_special_bits() {
    let d = TestDir::new("metadata-modes");
    let src = d.file("source", "executable");
    tagged(&src, b"user.tag", b"tag");
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o6777)).unwrap();
    let dst = d.join("copy");
    let flag = AtomicBool::new(false);
    let mut sink = |_: u64, _: u64| {
        let mode = dst.metadata().unwrap().mode() & 0o7777;
        assert_eq!(mode & 0o7000, 0, "never exposes set-id bits during the copy");
        assert_eq!(mode & 0o077 & !copyfile::keep_mode(0o6777), 0);
    };
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None, manifest: None };
    copyfile::copy_any(&src, &dst, &mut p).unwrap();
    assert_eq!(dst.metadata().unwrap().mode() & 0o7777, copyfile::keep_mode(0o6777));
}

#[test]
fn source_and_destination_path_swaps_cannot_redirect_metadata() {
    let d = TestDir::new("metadata-swap");
    let src = d.file("source", "selected");
    let dst = d.join("copy");
    let outside = d.file("outside", "not selected");
    tagged(&src, b"user.tag", b"selected");
    tagged(&outside, b"user.tag", b"outside");
    let before = dated(&src, 1);
    let outside_before = dated(&outside, 2);
    let flag = AtomicBool::new(false);
    let mut swapped = false;
    let mut sink = |_: u64, _: u64| {
        if swapped { return; }
        swapped = true;
        std::fs::rename(&src, d.join("source-held")).unwrap();
        std::fs::rename(&dst, d.join("copy-held")).unwrap();
        std::os::unix::fs::symlink(&outside, &src).unwrap();
        std::os::unix::fs::symlink(&outside, &dst).unwrap();
    };
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None, manifest: None };
    copyfile::copy_any(&src, &dst, &mut p).unwrap();
    same_times(&d.join("copy-held"), &before);
    same_times(&outside, &outside_before);
    assert_eq!(attr(&d.join("copy-held"), b"user.tag"), b"selected");
    assert_eq!(attr(&outside, b"user.tag"), b"outside");
}

extern "C" { fn geteuid() -> u32; }

// Changing permissions after the byte callback makes reading the source xattr fail.
// This targets metadata failure after the data arrived, not an early open failure.
#[test]
fn metadata_failure_reports_partial_and_restores_readonly_destination_mode() {
    if unsafe { geteuid() } == 0 { return; } // Root bypasses DAC; exercised as an ordinary user.
    let d = TestDir::new("metadata-failure");
    let src = d.file("source", "body");
    tagged(&src, b"user.tag", b"important");
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o400)).unwrap();
    let dst = d.join("copy");
    let flag = AtomicBool::new(false);
    let mut sink = |_: u64, _: u64| std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0)).unwrap();
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None, manifest: None };
    let result = copyfile::copy_any(&src, &dst, &mut p);
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o400)).unwrap();
    let error = result.expect_err("metadata could not be read");
    assert_eq!(error.where_, "copy metadata");
    assert_eq!(error.msg, "could not preserve metadata: permission denied");
    assert_eq!(p.partial, Some(dst.clone()));
    assert_eq!(std::fs::read(&dst).unwrap(), b"body");
    assert!(src.exists());
    assert_eq!(dst.metadata().unwrap().mode() & 0o7777, copyfile::keep_mode(0o400));
}

#[test]
fn directory_metadata_failure_reports_the_whole_partial_tree() {
    if unsafe { geteuid() } == 0 { return; }
    let d = TestDir::new("metadata-dir-failure");
    let src = d.dir("source");
    d.file("source/child", "body");
    tagged(&src, b"user.tag", b"important");
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o500)).unwrap();
    let dst = d.join("copy");
    let flag = AtomicBool::new(false);
    let mut sink = |_: u64, _: u64| std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0)).unwrap();
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None, manifest: None };
    let result = copyfile::copy_any(&src, &dst, &mut p);
    std::fs::set_permissions(&src, std::fs::Permissions::from_mode(0o700)).unwrap();
    let error = result.expect_err("directory metadata could not be read");
    assert_eq!(error.where_, "copy metadata");
    assert_eq!(error.msg, "could not preserve metadata: permission denied");
    assert_eq!(p.partial, Some(dst.clone()));
    assert_eq!(std::fs::read(dst.join("child")).unwrap(), b"body");
    assert_eq!(dst.metadata().unwrap().mode() & 0o7777, copyfile::keep_mode(0o500));
}

#[test]
fn user_attributes_copy_but_posix_acl_does_not() {
    let d = TestDir::new("metadata-acl");
    let src = d.file("source", "body");
    let mut acl = 2u32.to_le_bytes().to_vec();
    for (tag, perm, id) in [(1u16, 6u16, u32::MAX), (2, 4, unsafe { geteuid() } + 1),
        (4, 0, u32::MAX), (16, 4, u32::MAX), (32, 0, u32::MAX)] {
        acl.extend(tag.to_le_bytes()); acl.extend(perm.to_le_bytes()); acl.extend(id.to_le_bytes());
    }
    tagged(&src, b"system.posix_acl_access", &acl);
    tagged(&src, b"user.tag", b"retained");
    let dst = d.join("copy");
    copy(&src, &dst);
    assert_eq!(attr(&dst, b"user.tag"), b"retained");
    let source_names = names(&File::open(&src).unwrap()).unwrap();
    assert!(source_names.split(|b| *b == 0).any(|n| n == b"system.posix_acl_access"));
    let dest_names = names(&File::open(&dst).unwrap()).unwrap();
    assert!(!dest_names.split(|b| *b == 0).any(|n| n == b"system.posix_acl_access"));
}

#[test]
fn restored_mtime_is_recorded_in_the_copy_manifest_for_undo() {
    let d = TestDir::new("metadata-manifest");
    let src = d.dir("source");
    let child = d.file("source/child", "body");
    dated(&child, 1);
    let dst = d.join("copy");
    let flag = AtomicBool::new(false);
    let mut sink = |_: u64, _: u64| {};
    let mut p = copyfile::Progress { cancel: &flag, on_bytes: &mut sink, tree: None, partial: None,
        manifest: copymanifest::writer_for(&src, &dst) };
    copyfile::copy_any(&src, &dst, &mut p).unwrap();
    let handle = p.manifest.take().unwrap().finish().unwrap().unwrap();
    let _outcome = copymanifest::remove_owned(&handle);
    assert!(!dst.exists(), "an unchanged copy is removable after its old timestamp is restored");
    assert!(child.exists());
}

#[test]
fn changing_attribute_sizes_retry_with_a_bounded_number_of_calls() {
    let d = TestDir::new("metadata-size-race");
    let path = d.file("source", "");
    let file = File::open(&path).unwrap();
    let name = CString::new("user.growing").unwrap();
    set(&file, &name, b"a").unwrap();
    let mut calls = 0;
    let bytes = read_bytes(|p, size| {
        calls += 1;
        if calls == 2 { set(&file, &name, b"abc").unwrap(); }
        unsafe { fgetxattr(file.as_raw_fd(), name.as_ptr(), p, size) }
    }).unwrap();
    assert_eq!(bytes, b"abc");
    assert_eq!(calls, 4);
    calls = 0;
    let error = read_bytes(|p, size| {
        calls += 1;
        if !p.is_null() { set(&file, &name, &vec![b'x'; size + 1]).unwrap(); }
        unsafe { fgetxattr(file.as_raw_fd(), name.as_ptr(), p, size) }
    }).unwrap_err();
    assert_eq!(error.kind(), io::ErrorKind::Interrupted);
    assert_eq!(calls, 6);
}

#[test]
fn oversized_attributes_and_syscall_errors_do_not_allocate_or_loop() {
    let mut calls = 0;
    let error = read_bytes(|_, _| { calls += 1; (MAX_XATTR + 1) as isize }).unwrap_err();
    assert_eq!(error.kind(), io::ErrorKind::InvalidData);
    assert_eq!(calls, 1);
    let error = read_bytes(|p, size| unsafe { flistxattr(-1, p.cast(), size) }).unwrap_err();
    assert_eq!(error.raw_os_error(), Some(9));
}

#[test]
fn an_empty_value_still_performs_a_nonzero_capacity_read() {
    let mut calls = 0;
    let bytes = read_bytes(|p, size| {
        calls += 1;
        if calls == 1 { assert!(p.is_null()); assert_eq!(size, 0); }
        else { assert!(!p.is_null()); assert_eq!(size, 1); }
        0
    }).unwrap();
    assert!(bytes.is_empty());
    assert_eq!(calls, 2);
}
