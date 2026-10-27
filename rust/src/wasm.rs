// SPDX-License-Identifier: GPL-3.0-only
//
// The runtime of Map2Check's `--wasm` mode (decision D2). Map2Check lifts a
// WebAssembly binary to C with wabt's wasm2c, instruments the lifted code and
// links `WasmRuntimeStubs.bc` for the `wasm_rt_*` functions the lifted code
// calls. This module is that support, ported from the C runtime of Map2Check
// `develop`:
//
//   - `rt`: `WasmRuntimeStubs.c` (calloc/realloc based memory, KLEE-friendly),
//     with `wasm_rt_memory_t` and `wasm_rt_funcref_table_t` mirrored from
//     wabt 1.0.41's `wasm-rt.h` (layout checked by the `layout` test against
//     the real header, see below);
//   - `map2check_wasm_malloc`, `map2check_wasm_free` and
//     `map2check_wasm_check_access`: `AnalysisModeMemtrack.c:385-430`, the
//     per-allocation bounds check of lifted code, over the offset-keyed table
//     in `AnalysisState::wasm_allocs` (`memtrack::wasm_*`).
//
// Unsafe code is confined to this file (raw wasm-rt structs and libc
// allocation) and `ffi.rs`.

use crate::{analysismode::mode::Check, caller::ViolatedProperty, ffi::ffi_guard, memtrack, state};

/// Whether `check` is active in the selected analysis mode.
fn check_active(check: Check) -> bool {
    crate::analysismode::mode::check_enabled(state::config().mode, check)
}

/// Records a violation and, with a mode set, ends the run (the same path as
/// every other check: first violation final, abort in a Map2Check run).
fn record(property: ViolatedProperty, line: u32) {
    match state::with_state(|s| {
        let first = s.result.ok;
        s.set_false(property, line, "");
        Ok(first)
    }) {
        Ok(true) => crate::output::termination::on_violation(),
        Ok(false) => {}
        Err(e) => crate::output::termination::log_error(&e),
    }
}

// ── The memory checks of lifted code ────────────────────────────────────────

/// Registers the block that the lifted `malloc` returned at linear-memory
/// `offset` (`map2check_wasm_malloc`, `AnalysisModeMemtrack.c:385-397`). The
/// pass emits the call right after the call to `w2c_*_malloc`, with the
/// zero-extended result and size. Offsets 0 and `(uint64_t)-1` are ignored.
/// Tracking happens in every mode.
pub extern "C" fn map2check_wasm_malloc(offset: u64, size: u64) {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                memtrack::wasm_register_malloc(&mut s.wasm_allocs, offset, size);
                Ok(())
            }) {
                crate::output::termination::log_error(&e);
            }
        },
        (),
    );
}

/// Releases the block at linear-memory `offset` (`map2check_wasm_free`,
/// `AnalysisModeMemtrack.c:399-407`). An offset that was never registered is
/// a `MEMSAFETY_FREE` violation at `line` (the pass sends the source line as
/// an `i64`); an already freed block is found again and is not an error.
/// The violation is reported only where the memory checks are active.
pub extern "C" fn map2check_wasm_free(offset: u64, line: i64) {
    ffi_guard(
        || {
            let found = match state::with_state(|s| {
                Ok(memtrack::wasm_register_free(&mut s.wasm_allocs, offset))
            }) {
                Ok(found) => found,
                Err(e) => {
                    crate::output::termination::log_error(&e);
                    return;
                }
            };
            if !found && check_active(Check::Free) {
                // develop passes `int line`: the low 32 bits.
                record(ViolatedProperty::MemsafetyFree, line as i32 as u32);
            }
        },
        (),
    );
}

/// Checks that `access_size` bytes at linear-memory `offset` lie inside a
/// live block (`map2check_wasm_check_access`,
/// `AnalysisModeMemtrack.c:416-423`). The pass emits it before every load and
/// store through the lifted memory. A bad access is reported as develop does,
/// `FALSE_OVERFLOW` with line 0 and no function name: the report tag is
/// `OVERFLOW`. Reported only where the memory checks are active.
pub extern "C" fn map2check_wasm_check_access(offset: u64, access_size: u64) {
    ffi_guard(
        || {
            if !check_active(Check::Deref) {
                return;
            }
            let valid = match state::with_state(|s| {
                Ok(memtrack::wasm_is_valid_access(
                    &s.wasm_allocs,
                    offset,
                    access_size,
                ))
            }) {
                Ok(valid) => valid,
                Err(e) => {
                    crate::output::termination::log_error(&e);
                    return;
                }
            };
            if !valid {
                record(ViolatedProperty::Overflow, 0);
            }
        },
        (),
    );
}

// ── `WasmRuntimeStubs.c` ────────────────────────────────────────────────────

/// The `wasm_rt_*` functions the lifted code calls. Not part of the Map2Check
/// C header (`wasm-rt.h` declares them), so cbindgen skips this module.
///
/// cbindgen:ignore
#[allow(non_camel_case_types)]
pub mod rt {
    use std::os::raw::{c_char, c_void};
    use std::sync::atomic::{AtomicBool, Ordering};

    use crate::ffi::ffi_guard;

    extern "C" {
        fn calloc(count: usize, size: usize) -> *mut c_void;
        fn realloc(ptr: *mut c_void, size: usize) -> *mut c_void;
        fn free(ptr: *mut c_void);
    }

    /// `wasm_rt_memory_t` of wabt 1.0.41 (`wasm-rt.h:466-482`).
    #[repr(C)]
    #[derive(Debug, Clone, Copy)]
    pub struct wasm_rt_memory_t {
        pub data: *mut u8,
        pub data_end: *mut u8,
        pub page_size: u32,
        pub pages: u64,
        pub max_pages: u64,
        pub size: u64,
        pub is64: bool,
    }

    /// `wasm_rt_tailcallee_t` (`wasm-rt.h:421-425`).
    #[repr(C)]
    #[derive(Debug, Clone, Copy)]
    pub struct wasm_rt_tailcallee_t {
        pub func:
            Option<unsafe extern "C" fn(*mut *mut c_void, *mut c_void, *mut wasm_rt_tailcallee_t)>,
    }

    /// `wasm_rt_funcref_t` (`wasm-rt.h:437-453`).
    #[repr(C)]
    #[derive(Debug, Clone, Copy)]
    pub struct wasm_rt_funcref_t {
        pub func_type: *const c_char,
        pub func: Option<unsafe extern "C" fn()>,
        pub func_tailcallee: wasm_rt_tailcallee_t,
        pub module_instance: *mut c_void,
    }

    /// `wasm_rt_funcref_table_t` (`wasm-rt.h:519-529`).
    #[repr(C)]
    #[derive(Debug, Clone, Copy)]
    pub struct wasm_rt_funcref_table_t {
        pub data: *mut wasm_rt_funcref_t,
        pub max_size: u32,
        pub size: u32,
    }

    /// Allocates linear memory with `calloc` (the default wasm-rt uses
    /// `mmap`, which KLEE models poorly). As in develop, `is64` and the
    /// `is64` field are not touched.
    ///
    /// # Safety
    /// `mem` must point to a writable `wasm_rt_memory_t`.
    pub(super) unsafe fn wasm_rt_allocate_memory_impl(
        mem: *mut wasm_rt_memory_t,
        initial_pages: u64,
        max_pages: u64,
        _is64: bool,
        page_size: u32,
    ) {
        ffi_guard(
            || {
                let byte_length = u64::from(page_size).wrapping_mul(initial_pages);
                // SAFETY: calloc has no preconditions; the caller guarantees `mem`.
                let data = unsafe { calloc(1, byte_length as usize) }.cast::<u8>();
                // SAFETY: caller guarantees `mem` is a valid, writable descriptor.
                let mem = unsafe { &mut *mem };
                mem.data = data;
                mem.data_end = data.wrapping_add(byte_length as usize);
                mem.page_size = page_size;
                mem.size = byte_length;
                mem.pages = initial_pages;
                mem.max_pages = max_pages;
            },
            (),
        );
    }

    /// Grows linear memory by `pages` with `realloc`. Returns the previous
    /// page count, or `UINT32_MAX` on failure, as `wasm-rt.h` documents.
    ///
    /// # Safety
    /// `mem` must point to a memory set up by [`wasm_rt_allocate_memory`].
    pub(super) unsafe fn wasm_rt_grow_memory_impl(mem: *mut wasm_rt_memory_t, pages: u64) -> u64 {
        ffi_guard(
            || {
                let failure = u64::from(u32::MAX);
                // SAFETY: caller guarantees `mem` is a valid descriptor.
                let mem = unsafe { &mut *mem };
                let old_pages = mem.pages;
                let new_pages = old_pages.wrapping_add(pages);
                if new_pages < old_pages || new_pages > mem.max_pages {
                    return failure;
                }
                if pages == 0 {
                    return old_pages;
                }
                let page_size = if mem.page_size != 0 {
                    mem.page_size
                } else {
                    65536
                };
                let old_size = mem.size;
                let new_size = new_pages.wrapping_mul(u64::from(page_size));
                // SAFETY: `mem.data` came from calloc/realloc (or is null).
                let new_data =
                    unsafe { realloc(mem.data.cast::<c_void>(), new_size as usize) }.cast::<u8>();
                if new_data.is_null() {
                    return failure;
                }
                if new_size > old_size {
                    // SAFETY: the block now holds `new_size` bytes and the
                    // range starts at `old_size`, inside it.
                    unsafe {
                        new_data
                            .add(old_size as usize)
                            .write_bytes(0, (new_size - old_size) as usize);
                    }
                }
                mem.data = new_data;
                mem.data_end = new_data.wrapping_add(new_size as usize);
                mem.pages = new_pages;
                mem.size = new_size;
                old_pages
            },
            u64::from(u32::MAX),
        )
    }

    /// Frees linear memory.
    ///
    /// # Safety
    /// `mem` must point to a memory set up by [`wasm_rt_allocate_memory`].
    pub(super) unsafe fn wasm_rt_free_memory_impl(mem: *mut wasm_rt_memory_t) {
        ffi_guard(
            || {
                // SAFETY: caller guarantees `mem` is a valid descriptor whose
                // data came from calloc/realloc.
                unsafe {
                    free((*mem).data.cast::<c_void>());
                    (*mem).data = std::ptr::null_mut();
                    (*mem).size = 0;
                }
            },
            (),
        );
    }

    /// Allocates a funcref table of `elements` null entries. Unlike develop's
    /// stub, which sizes each element as `sizeof(void*)` although a
    /// `wasm_rt_funcref_t` is four words (a heap overflow once the module's
    /// element segments are written), each element gets its real size.
    /// `max_size` is left untouched, as in develop.
    ///
    /// # Safety
    /// `table` must point to a writable `wasm_rt_funcref_table_t`.
    pub(super) unsafe fn wasm_rt_allocate_funcref_table_impl(
        table: *mut wasm_rt_funcref_table_t,
        elements: u32,
        _max_elements: u32,
    ) {
        ffi_guard(
            || {
                // SAFETY: calloc has no preconditions.
                let data =
                    unsafe { calloc(elements as usize, std::mem::size_of::<wasm_rt_funcref_t>()) }
                        .cast::<wasm_rt_funcref_t>();
                // SAFETY: caller guarantees `table` is valid and writable.
                unsafe {
                    (*table).data = data;
                    (*table).size = elements;
                }
            },
            (),
        );
    }

    /// Frees a funcref table.
    ///
    /// # Safety
    /// `table` must point to a table set up by
    /// [`wasm_rt_allocate_funcref_table`].
    pub(super) unsafe fn wasm_rt_free_funcref_table_impl(table: *mut wasm_rt_funcref_table_t) {
        ffi_guard(
            || {
                // SAFETY: caller guarantees `table` is valid; data is calloc'd.
                unsafe {
                    free((*table).data.cast::<c_void>());
                    (*table).data = std::ptr::null_mut();
                }
            },
            (),
        );
    }

    /// The old API's body of this C name, not exported since 2.0.0 (Task
    /// 2.10): the C name belongs to the IR module `WasmRuntimeStubs.ll`.
    /// Rust tests call it; the body is `wasm_rt_allocate_memory_impl`, which
    /// `__m2c_rt_wasm_*` also calls.
    ///
    /// # Safety
    /// As `wasm_rt_allocate_memory_impl`.
    pub unsafe extern "C" fn wasm_rt_allocate_memory(
        mem: *mut wasm_rt_memory_t,
        initial_pages: u64,
        max_pages: u64,
        is64: bool,
        page_size: u32,
    ) {
        // SAFETY: forwarded caller contract.
        ffi_guard(
            || unsafe {
                wasm_rt_allocate_memory_impl(mem, initial_pages, max_pages, is64, page_size)
            },
            (),
        )
    }

    /// The old API's body of this C name, not exported since 2.0.0 (Task
    /// 2.10): the C name belongs to the IR module `WasmRuntimeStubs.ll`.
    /// Rust tests call it; the body is `wasm_rt_grow_memory_impl`, which
    /// `__m2c_rt_wasm_*` also calls.
    ///
    /// # Safety
    /// As `wasm_rt_grow_memory_impl`.
    pub unsafe extern "C" fn wasm_rt_grow_memory(mem: *mut wasm_rt_memory_t, pages: u64) -> u64 {
        // SAFETY: forwarded caller contract.
        ffi_guard(
            || unsafe { wasm_rt_grow_memory_impl(mem, pages) },
            u64::from(u32::MAX),
        )
    }

    /// The old API's body of this C name, not exported since 2.0.0 (Task
    /// 2.10): the C name belongs to the IR module `WasmRuntimeStubs.ll`.
    /// Rust tests call it; the body is `wasm_rt_free_memory_impl`, which
    /// `__m2c_rt_wasm_*` also calls.
    ///
    /// # Safety
    /// As `wasm_rt_free_memory_impl`.
    pub unsafe extern "C" fn wasm_rt_free_memory(mem: *mut wasm_rt_memory_t) {
        // SAFETY: forwarded caller contract.
        ffi_guard(|| unsafe { wasm_rt_free_memory_impl(mem) }, ())
    }

    /// The old API's body of this C name, not exported since 2.0.0 (Task
    /// 2.10): the C name belongs to the IR module `WasmRuntimeStubs.ll`.
    /// Rust tests call it; the body is `wasm_rt_allocate_funcref_table_impl`, which
    /// `__m2c_rt_wasm_*` also calls.
    ///
    /// # Safety
    /// As `wasm_rt_allocate_funcref_table_impl`.
    pub unsafe extern "C" fn wasm_rt_allocate_funcref_table(
        table: *mut wasm_rt_funcref_table_t,
        elements: u32,
        max_elements: u32,
    ) {
        // SAFETY: forwarded caller contract.
        ffi_guard(
            || unsafe { wasm_rt_allocate_funcref_table_impl(table, elements, max_elements) },
            (),
        )
    }

    /// The old API's body of this C name, not exported since 2.0.0 (Task
    /// 2.10): the C name belongs to the IR module `WasmRuntimeStubs.ll`.
    /// Rust tests call it; the body is `wasm_rt_free_funcref_table_impl`, which
    /// `__m2c_rt_wasm_*` also calls.
    ///
    /// # Safety
    /// As `wasm_rt_free_funcref_table_impl`.
    pub unsafe extern "C" fn wasm_rt_free_funcref_table(table: *mut wasm_rt_funcref_table_t) {
        // SAFETY: forwarded caller contract.
        ffi_guard(|| unsafe { wasm_rt_free_funcref_table_impl(table) }, ())
    }

    /// "Always initialised for KLEE": true from the start.
    static INITIALIZED: AtomicBool = AtomicBool::new(true);

    pub(super) fn wasm_rt_is_initialized_impl() -> bool {
        ffi_guard(|| INITIALIZED.load(Ordering::Relaxed), true)
    }

    pub(super) fn wasm_rt_init_impl() {
        ffi_guard(|| INITIALIZED.store(true, Ordering::Relaxed), ());
    }

    pub(super) fn wasm_rt_free_impl() {
        ffi_guard(|| INITIALIZED.store(false, Ordering::Relaxed), ());
    }

    /// Not exported since 2.0.0 (Task 2.10), as above.
    pub extern "C" fn wasm_rt_is_initialized() -> bool {
        ffi_guard(wasm_rt_is_initialized_impl, true)
    }

    pub extern "C" fn wasm_rt_init() {
        ffi_guard(wasm_rt_init_impl, ())
    }

    pub extern "C" fn wasm_rt_free() {
        ffi_guard(wasm_rt_free_impl, ())
    }

    /// A trap ends the run. develop calls `map2check_error()`, which writes no
    /// property and aborts, so the frontend reads UNKNOWN; here the run
    /// records an UNKNOWN verdict (a first violation, final) and aborts.
    /// `wasm-rt.h` declares the function `noreturn`, so it never returns, not
    /// even with no analysis mode set.
    pub(super) fn wasm_rt_trap_impl(code: u32) -> ! {
        ffi_guard(
            || {
                let _ = code;
                super::record(crate::caller::ViolatedProperty::Unknown, 0);
            },
            (),
        );
        std::process::abort()
    }

    /// Not exported since 2.0.0 (Task 2.10), as above.
    pub extern "C" fn wasm_rt_trap(code: u32) -> ! {
        ffi_guard(|| wasm_rt_trap_impl(code), ());
        std::process::abort()
    }
}

pub use rt::*;

// ── Core entry points of `WasmRuntimeStubs.ll` (Task 2.9, D7 A-fwd) ─────────
//
// The IR module `WasmRuntimeStubs.ll` (`scripts/runtime-ir/gen_ll.py`) defines
// the C names `wasm_rt_*` the lifted code calls and forwards each one to the
// `__m2c_rt_wasm_*` below; `w2c_wasi__snapshot__preview1_proc_exit` has an
// empty C body (`WasmRuntimeStubs.c:90-93`) and is an empty IR define. The
// descriptors cross the C ABI as `void *` (the header does not know the wabt
// structs). The behaviour is `rt`'s, one-to-one with `WasmRuntimeStubs.c`.
// Since 2.0.0 (Task 2.10) the `wasm_rt_*` functions of `rt` are Rust only
// (tests call them); they and these entry points share the `*_impl` bodies
// (a `__m2c` function must never call the C name: the IR module defines it
// and forwards back here).

use std::os::raw::c_void;

/// `wasm_rt_allocate_memory` (`WasmRuntimeStubs.c:22-35`): `calloc`ed linear
/// memory of `initial_pages` pages; `is64` is not stored.
///
/// # Safety
/// `mem` must point to a writable `wasm_rt_memory_t`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_wasm_allocate_memory(
    mem: *mut c_void,
    initial_pages: u64,
    max_pages: u64,
    is64: bool,
    page_size: u32,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe {
            rt::wasm_rt_allocate_memory_impl(mem.cast(), initial_pages, max_pages, is64, page_size)
        },
        (),
    );
}

/// `wasm_rt_grow_memory` (`WasmRuntimeStubs.c:41-63`): the previous page
/// count, or `UINT32_MAX` on failure.
///
/// # Safety
/// `mem` must point to a memory set up by `__m2c_rt_wasm_allocate_memory`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_wasm_grow_memory(mem: *mut c_void, pages: u64) -> u64 {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt::wasm_rt_grow_memory_impl(mem.cast(), pages) },
        u64::from(u32::MAX),
    )
}

/// `wasm_rt_free_memory` (`WasmRuntimeStubs.c:66-70`).
///
/// # Safety
/// `mem` must point to a memory set up by `__m2c_rt_wasm_allocate_memory`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_wasm_free_memory(mem: *mut c_void) {
    // SAFETY: forwarded caller contract.
    ffi_guard(|| unsafe { rt::wasm_rt_free_memory_impl(mem.cast()) }, ());
}

/// `wasm_rt_allocate_funcref_table` (`WasmRuntimeStubs.c:73-78`; the element
/// size is SD-19).
///
/// # Safety
/// `table` must point to a writable `wasm_rt_funcref_table_t`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_wasm_allocate_funcref_table(
    table: *mut c_void,
    elements: u32,
    max_elements: u32,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt::wasm_rt_allocate_funcref_table_impl(table.cast(), elements, max_elements) },
        (),
    );
}

/// `wasm_rt_free_funcref_table` (`WasmRuntimeStubs.c:81-84`).
///
/// # Safety
/// `table` must point to a table set up by
/// `__m2c_rt_wasm_allocate_funcref_table`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_wasm_free_funcref_table(table: *mut c_void) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt::wasm_rt_free_funcref_table_impl(table.cast()) },
        (),
    );
}

/// `wasm_rt_init` (`WasmRuntimeStubs.c:102-104`): marks the runtime initialised.
#[no_mangle]
pub extern "C" fn __m2c_rt_wasm_init() {
    ffi_guard(rt::wasm_rt_init_impl, ());
}

/// `wasm_rt_free` (`WasmRuntimeStubs.c:106-108`): marks it not initialised.
#[no_mangle]
pub extern "C" fn __m2c_rt_wasm_free() {
    ffi_guard(rt::wasm_rt_free_impl, ());
}

/// `wasm_rt_is_initialized` (`WasmRuntimeStubs.c:98-100`): true from the start.
#[no_mangle]
pub extern "C" fn __m2c_rt_wasm_is_initialized() -> bool {
    ffi_guard(rt::wasm_rt_is_initialized_impl, true)
}

/// `wasm_rt_trap` (`WasmRuntimeStubs.c:110-116`): never returns. Records an
/// UNKNOWN verdict, then aborts (SD-19).
#[no_mangle]
pub extern "C" fn __m2c_rt_wasm_trap(code: u32) {
    ffi_guard(|| rt::wasm_rt_trap_impl(code), ());
    // The impl aborts; a panic that ffi_guard caught must not return either.
    std::process::abort()
}

#[cfg(test)]
mod tests {
    use super::rt::*;
    use std::mem::{offset_of, size_of};
    use std::process::Command;

    /// Compares the Rust mirrors with the layout the C compiler gives
    /// `wasm-rt.h`. Runs only when `WASM_RT_INCLUDE` names the directory of
    /// the header (wabt 1.0.41: `/opt/wabt-1.0.41/include`); the library
    /// itself never needs `cc`. The probe is built in a temporary directory
    /// and is not linked into the library.
    #[test]
    fn layout_matches_wasm_rt_h() {
        let Some(include) = std::env::var_os("WASM_RT_INCLUDE") else {
            eprintln!(
                "layout_matches_wasm_rt_h: SKIPPED, WASM_RT_INCLUDE is not set \
                 (set it to the directory of wabt 1.0.41's wasm-rt.h to run it)"
            );
            return;
        };
        let dir = tempfile::tempdir().unwrap();
        let src = dir.path().join("probe.c");
        std::fs::write(
            &src,
            r#"
#include <stdio.h>
#include <stddef.h>
#include "wasm-rt.h"
#define P(name, value) printf("%s %zu\n", name, (size_t)(value))
int main(void) {
  P("memory.size", sizeof(wasm_rt_memory_t));
  P("memory.data", offsetof(wasm_rt_memory_t, data));
  P("memory.data_end", offsetof(wasm_rt_memory_t, data_end));
  P("memory.page_size", offsetof(wasm_rt_memory_t, page_size));
  P("memory.pages", offsetof(wasm_rt_memory_t, pages));
  P("memory.max_pages", offsetof(wasm_rt_memory_t, max_pages));
  P("memory.size_field", offsetof(wasm_rt_memory_t, size));
  P("memory.is64", offsetof(wasm_rt_memory_t, is64));
  P("funcref.size", sizeof(wasm_rt_funcref_t));
  P("funcref.func_type", offsetof(wasm_rt_funcref_t, func_type));
  P("funcref.func", offsetof(wasm_rt_funcref_t, func));
  P("funcref.func_tailcallee", offsetof(wasm_rt_funcref_t, func_tailcallee));
  P("funcref.module_instance", offsetof(wasm_rt_funcref_t, module_instance));
  P("table.size", sizeof(wasm_rt_funcref_table_t));
  P("table.data", offsetof(wasm_rt_funcref_table_t, data));
  P("table.max_size", offsetof(wasm_rt_funcref_table_t, max_size));
  P("table.size_field", offsetof(wasm_rt_funcref_table_t, size));
  P("trap_t.size", sizeof(wasm_rt_trap_t));
  return 0;
}
"#,
        )
        .unwrap();
        let exe = dir.path().join("probe");
        let cc = std::env::var("CC").unwrap_or_else(|_| "cc".to_string());
        let built = Command::new(cc)
            .arg("-I")
            .arg(&include)
            .arg(&src)
            .arg("-o")
            .arg(&exe)
            .output()
            .expect("cc must be installed to run the layout test");
        assert!(
            built.status.success(),
            "the probe does not compile: {}",
            String::from_utf8_lossy(&built.stderr)
        );
        let run = Command::new(&exe).output().unwrap();
        assert!(run.status.success());
        let text = String::from_utf8(run.stdout).unwrap();
        let get = |name: &str| -> usize {
            text.lines()
                .find_map(|l| l.strip_prefix(name)?.strip_prefix(' ')?.parse().ok())
                .unwrap_or_else(|| panic!("probe printed no `{name}`: {text}"))
        };
        let expected = [
            ("memory.size", size_of::<wasm_rt_memory_t>()),
            ("memory.data", offset_of!(wasm_rt_memory_t, data)),
            ("memory.data_end", offset_of!(wasm_rt_memory_t, data_end)),
            ("memory.page_size", offset_of!(wasm_rt_memory_t, page_size)),
            ("memory.pages", offset_of!(wasm_rt_memory_t, pages)),
            ("memory.max_pages", offset_of!(wasm_rt_memory_t, max_pages)),
            ("memory.size_field", offset_of!(wasm_rt_memory_t, size)),
            ("memory.is64", offset_of!(wasm_rt_memory_t, is64)),
            ("funcref.size", size_of::<wasm_rt_funcref_t>()),
            (
                "funcref.func_type",
                offset_of!(wasm_rt_funcref_t, func_type),
            ),
            ("funcref.func", offset_of!(wasm_rt_funcref_t, func)),
            (
                "funcref.func_tailcallee",
                offset_of!(wasm_rt_funcref_t, func_tailcallee),
            ),
            (
                "funcref.module_instance",
                offset_of!(wasm_rt_funcref_t, module_instance),
            ),
            ("table.size", size_of::<wasm_rt_funcref_table_t>()),
            ("table.data", offset_of!(wasm_rt_funcref_table_t, data)),
            (
                "table.max_size",
                offset_of!(wasm_rt_funcref_table_t, max_size),
            ),
            (
                "table.size_field",
                offset_of!(wasm_rt_funcref_table_t, size),
            ),
            // `wasm_rt_trap` takes the enum as a u32.
            ("trap_t.size", size_of::<u32>()),
        ];
        for (name, rust) in expected {
            assert_eq!(rust, get(name), "layout of `{name}` differs from wasm-rt.h");
        }
    }
}
