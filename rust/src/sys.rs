// SPDX-License-Identifier: GPL-3.0-only
//
// The C library calls of the result channel: create, write, rename, link
// and remove the result files, read the environment, write a diagnostic to
// stderr. They are the calls `std::fs`, `std::env` and `std::process` made
// before (`open64`, `write`, `close`, `rename`, `linkat`, `unlink`,
// `getpid`, `getenv`, `__xpg_strerror_r`) with the same flags, so KLEE's
// POSIX model sees the same system calls; without `std::io`, `std::path` and
// `core::fmt`, which made up much of the drop-in core that `afl-clang-fast`
// compiles three times per Map2Check run (Task 3.3).
//
// With `ffi.rs` and `wasm.rs`, the only module with unsafe code; every
// unsafe block has a SAFETY comment.

use std::ffi::c_int;
use std::path::Path;

/// The libc functions, kept out of `include/map2check.h`: the library
/// does not define them.
///
/// cbindgen:ignore
mod libc {
    use std::ffi::{c_char, c_int, c_void};

    extern "C" {
        pub(super) fn open64(path: *const c_char, flags: c_int, ...) -> c_int;
        pub(super) fn write(fd: c_int, buf: *const c_void, count: usize) -> isize;
        pub(super) fn close(fd: c_int) -> c_int;
        pub(super) fn rename(old: *const c_char, new: *const c_char) -> c_int;
        pub(super) fn linkat(
            olddirfd: c_int,
            old: *const c_char,
            newdirfd: c_int,
            new: *const c_char,
            flags: c_int,
        ) -> c_int;
        pub(super) fn unlink(path: *const c_char) -> c_int;
        pub(super) fn getpid() -> c_int;
        pub(super) fn getenv(name: *const c_char) -> *mut c_char;
        pub(super) fn __errno_location() -> *mut c_int;
        #[link_name = "__xpg_strerror_r"]
        pub(super) fn strerror_r(errnum: c_int, buf: *mut c_char, len: usize) -> c_int;
    }
}
use libc::*;

const O_WRONLY: c_int = 0o1;
const O_CREAT: c_int = 0o100;
const O_EXCL: c_int = 0o200;
const O_TRUNC: c_int = 0o1000;
const O_CLOEXEC: c_int = 0o2000000;
const AT_FDCWD: c_int = -100;
const EINTR: c_int = 4;
const EEXIST: c_int = 17;
const ENOENT: c_int = 2;

/// Why a result file could not be written.
#[derive(Debug, Clone, Copy)]
pub enum FileError {
    /// The `errno` of the failed call.
    Os(i32),
    /// `write` wrote nothing.
    WriteZero,
    /// The path has a NUL byte.
    NulInPath,
    /// Old-API writers only.
    Other(&'static str),
}

impl FileError {
    /// The text `std::io::Error` printed for the same error, which
    /// the diagnostics kept: `<strerror> (os error <n>)`.
    pub fn describe(&self, out: &mut Vec<u8>) {
        match *self {
            FileError::Os(code) => {
                let mut buf = [0u8; 128];
                // SAFETY: a buffer of `buf.len()` bytes; the XSI strerror_r
                // writes a NUL-terminated message into it.
                let ok = unsafe { strerror_r(code, buf.as_mut_ptr().cast(), buf.len()) } == 0;
                if ok {
                    let len = buf.iter().position(|&b| b == 0).unwrap_or(buf.len());
                    out.extend_from_slice(&buf[..len]);
                } else {
                    out.extend_from_slice(b"Unknown error");
                }
                out.extend_from_slice(b" (os error ");
                crate::cfmt::put_i64(out, i64::from(code));
                out.push(b')');
            }
            FileError::WriteZero => out.extend_from_slice(b"failed to write whole buffer"),
            FileError::NulInPath => {
                out.extend_from_slice(b"file name contained an unexpected NUL byte");
            }
            FileError::Other(text) => out.extend_from_slice(text.as_bytes()),
        }
    }

    pub fn is_already_exists(&self) -> bool {
        matches!(self, FileError::Os(EEXIST))
    }

    pub fn is_not_found(&self) -> bool {
        matches!(self, FileError::Os(ENOENT))
    }

    fn is_interrupted(&self) -> bool {
        matches!(self, FileError::Os(EINTR))
    }
}

#[cfg(not(feature = "dropin"))]
impl std::fmt::Display for FileError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut text = Vec::new();
        self.describe(&mut text);
        f.write_str(&String::from_utf8_lossy(&text))
    }
}

pub type FileResult<T> = Result<T, FileError>;

fn errno() -> FileError {
    // SAFETY: `__errno_location` returns the calling thread's errno.
    FileError::Os(unsafe { *__errno_location() })
}

/// `dir/name` as a NUL-terminated path, joined as `Path::join` joins a
/// relative name.
pub fn c_path(dir: &Path, name: &[u8]) -> FileResult<Vec<u8>> {
    use std::os::unix::ffi::OsStrExt as _;
    let dir = dir.as_os_str().as_bytes();
    let mut path = Vec::with_capacity(dir.len() + name.len() + 2);
    path.extend_from_slice(dir);
    if !dir.is_empty() && !dir.ends_with(b"/") {
        path.push(b'/');
    }
    path.extend_from_slice(name);
    // A plain loop, not `contains`: that one is `memchr`, 125 more lines of
    // IR for a path of a few dozen bytes.
    if path.iter().any(|&b| b == 0) {
        return Err(FileError::NulInPath);
    }
    path.push(0);
    Ok(path)
}

/// An open file, closed on drop (the error of `close` is ignored, as
/// `std::fs::File` ignores it).
pub struct File(c_int);

impl File {
    fn open(path: &[u8], flags: c_int) -> FileResult<File> {
        loop {
            // SAFETY: `path` is NUL-terminated (`c_path`); the mode is the
            // third argument of an O_CREAT open.
            let fd = unsafe { open64(path.as_ptr().cast(), flags, 0o666 as c_int) };
            if fd >= 0 {
                return Ok(File(fd));
            }
            let e = errno();
            if !e.is_interrupted() {
                return Err(e);
            }
        }
    }

    /// `std::fs::File::create`: truncated, or created with mode 0666.
    pub fn create(path: &[u8]) -> FileResult<File> {
        File::open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC)
    }

    /// `OpenOptions::new().write(true).create_new(true)`.
    pub fn create_new(path: &[u8]) -> FileResult<File> {
        File::open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC)
    }

    /// `Write::write_all`.
    pub fn write_all(&mut self, mut bytes: &[u8]) -> FileResult<()> {
        while !bytes.is_empty() {
            let len = bytes.len().min(isize::MAX as usize);
            // SAFETY: `bytes` is valid for `len` bytes.
            let n = unsafe { write(self.0, bytes.as_ptr().cast(), len) };
            if n < 0 {
                let e = errno();
                if e.is_interrupted() {
                    continue;
                }
                return Err(e);
            }
            if n == 0 {
                return Err(FileError::WriteZero);
            }
            bytes = &bytes[n as usize..];
        }
        Ok(())
    }
}

impl Drop for File {
    fn drop(&mut self) {
        // SAFETY: the descriptor this value owns, closed once.
        unsafe { close(self.0) };
    }
}

fn check(result: c_int) -> FileResult<()> {
    if result == 0 {
        Ok(())
    } else {
        Err(errno())
    }
}

/// `std::fs::rename`.
pub fn rename_file(from: &[u8], to: &[u8]) -> FileResult<()> {
    // SAFETY: both paths are NUL-terminated (`c_path`).
    check(unsafe { rename(from.as_ptr().cast(), to.as_ptr().cast()) })
}

/// `std::fs::hard_link`.
pub fn hard_link(from: &[u8], to: &[u8]) -> FileResult<()> {
    // SAFETY: both paths are NUL-terminated (`c_path`).
    check(unsafe {
        linkat(
            AT_FDCWD,
            from.as_ptr().cast(),
            AT_FDCWD,
            to.as_ptr().cast(),
            0,
        )
    })
}

/// `std::fs::remove_file`.
pub fn remove_file(path: &[u8]) -> FileResult<()> {
    // SAFETY: the path is NUL-terminated (`c_path`).
    check(unsafe { unlink(path.as_ptr().cast()) })
}

/// `std::process::id`.
pub fn process_id() -> u32 {
    // SAFETY: `getpid` has no preconditions.
    unsafe { getpid() as u32 }
}

/// Whether the environment variable `name` is set,
/// `std::env::var_os(name).is_some()`. `name` ends with its NUL byte.
pub fn env_is_set(name: &[u8]) -> bool {
    if name.last() != Some(&0) || name[..name.len() - 1].iter().any(|&b| b == 0) {
        return false;
    }
    // SAFETY: a NUL-terminated name; the result is only compared with NULL.
    !unsafe { getenv(name.as_ptr().cast()) }.is_null()
}

/// Writes one diagnostic line, `[map2check] ` + `text` + newline, to
/// stderr. The host builds go through `eprintln!`, which the test harness
/// captures; the drop-in core writes the line with one `write(2)`.
pub fn diagnostic(text: &[u8]) {
    let mut line = Vec::with_capacity(text.len() + 13);
    line.extend_from_slice(b"[map2check] ");
    line.extend_from_slice(text);
    #[cfg(not(feature = "dropin"))]
    eprintln!("{}", String::from_utf8_lossy(&line));
    #[cfg(feature = "dropin")]
    {
        line.push(b'\n');
        let mut stderr = std::mem::ManuallyDrop::new(File(2));
        let _ = stderr.write_all(&line);
    }
}
