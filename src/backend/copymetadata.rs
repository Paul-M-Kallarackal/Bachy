// Metadata is applied through held descriptors: renaming either path cannot redirect it.
use std::ffi::{c_char, c_int, c_void, CString};
use std::fs::{File, FileTimes, Metadata};
use std::io;
use std::os::fd::AsRawFd;
use std::os::unix::fs::PermissionsExt;

// Linux limits both an xattr value and the returned name list to 64 KiB. Bound races too.
const MAX_XATTR: usize = 65_536;
const ERANGE: i32 = 34;
const EOPNOTSUPP: i32 = 95;

extern "C" {
    fn flistxattr(fd: c_int, list: *mut c_char, size: usize) -> isize;
    fn fgetxattr(fd: c_int, name: *const c_char, value: *mut c_void, size: usize) -> isize;
    fn fsetxattr(fd: c_int, name: *const c_char, value: *const c_void, size: usize, flags: c_int) -> c_int;
}

// A changing attribute cannot grow memory or keep a transfer busy forever.
fn read_bytes(mut read: impl FnMut(*mut c_void, usize) -> isize) -> io::Result<Vec<u8>> {
    for _ in 0..3 {
        let size = read(std::ptr::null_mut(), 0);
        if size < 0 {
            return Err(io::Error::last_os_error());
        }
        if size as usize > MAX_XATTR {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "extended attributes exceed the Linux size limit"));
        }
        // Nonzero capacity distinguishes an empty value from another size-only query.
        let mut bytes = vec![0u8; (size as usize).max(1)];
        let got = read(bytes.as_mut_ptr().cast(), bytes.len());
        if got >= 0 && got as usize <= bytes.len() {
            bytes.truncate(got as usize);
            return Ok(bytes);
        }
        let error = io::Error::last_os_error();
        if got < 0 && error.raw_os_error() != Some(ERANGE) {
            return Err(error);
        }
    }
    Err(io::Error::new(io::ErrorKind::Interrupted, "extended attributes kept changing during the copy"))
}

fn names(source: &File) -> io::Result<Vec<u8>> {
    match read_bytes(|p, size| unsafe { flistxattr(source.as_raw_fd(), p.cast(), size) }) {
        // A source filesystem without xattrs has no user attributes to preserve.
        Err(e) if e.raw_os_error() == Some(EOPNOTSUPP) => Ok(Vec::new()),
        other => other,
    }
}

fn value(source: &File, name: &CString) -> io::Result<Vec<u8>> {
    read_bytes(|p, size| unsafe { fgetxattr(source.as_raw_fd(), name.as_ptr(), p, size) })
}

fn set(destination: &File, name: &CString, bytes: &[u8]) -> io::Result<()> {
    let result = unsafe {
        fsetxattr(destination.as_raw_fd(), name.as_ptr(), bytes.as_ptr().cast(), bytes.len(), 0)
    };
    if result < 0 { Err(io::Error::last_os_error()) } else { Ok(()) }
}

// Deliberately exclude security.*, trusted.* and system.*: capabilities, ownership and ACL
// semantics require a separate policy. In particular, never grant an executable capabilities.
pub fn preserve(source: &File, destination: &File, before_read: &Metadata, final_mode: u32) -> io::Result<()> {
    let metadata = (|| {
        let names = names(source)?;
        let user_names: Vec<_> = names.split(|b| *b == 0).filter(|name| name.starts_with(b"user.")).collect();
        if !user_names.is_empty() {
            // fsetxattr checks inode permissions even with a writable descriptor. Only the
            // owner temporarily gains write access; other users' permissions never widen.
            let mode = destination.metadata()?.permissions().mode();
            if mode & 0o200 == 0 {
                destination.set_permissions(std::fs::Permissions::from_mode(mode | 0o200))?;
            }
        }
        for name in user_names {
            let name = CString::new(name).map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "invalid extended attribute name"))?;
            let bytes = value(source, &name)?;
            set(destination, &name, &bytes)?;
        }
        // This is the access time observed at open, not a pre-request snapshot: a parallel
        // size scan or another reader may already have advanced it. Finish directories last.
        destination.set_times(FileTimes::new()
            .set_accessed(before_read.accessed()?)
            .set_modified(before_read.modified()?))
    })();
    // Always restore the caller's source-and-umask mode, including on xattr/time failure.
    // A chmod failure is an error too; copying bytes alone is not successful preservation.
    destination.set_permissions(std::fs::Permissions::from_mode(final_mode))?;
    metadata
}

#[cfg(test)]
#[path = "copymetadata_tests.rs"]
mod tests;
