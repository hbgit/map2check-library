// SPDX-License-Identifier: GPL-3.0-only
//
// LibFuzzer nondeterministic value generation.
// Replaces nondet_gen_libfuzzer.c — eliminates all union type-punning
// by using f32::from_bits() / f64::from_bits() from safe Rust.

use std::sync::atomic::{AtomicPtr, AtomicUsize, Ordering};

static FUZZER_CURSOR: AtomicUsize = AtomicUsize::new(0);
static FUZZER_SIZE: AtomicUsize = AtomicUsize::new(0);
static FUZZER_DATA: AtomicPtr<u8> = AtomicPtr::new(std::ptr::null_mut());

/// Called by LibFuzzer before the test target runs.
///
/// # Safety
/// `data` must remain valid for the duration of one fuzzer iteration.
/// This is guaranteed by the LibFuzzer runtime contract.
#[no_mangle]
pub unsafe extern "C" fn LLVMFuzzerTestOneInput(data: *const u8, size: usize) -> i32 {
    crate::ffi::ffi_guard(
        || {
            crate::state::reset();

            if data.is_null() && size != 0 {
                return 0;
            }

            // SAFETY: LibFuzzer guarantees `data` is valid for `size` bytes.
            FUZZER_DATA.store(data as *mut u8, Ordering::SeqCst);
            FUZZER_SIZE.store(size, Ordering::SeqCst);
            FUZZER_CURSOR.store(0, Ordering::SeqCst);

            unsafe extern "C" {
                fn __map2check_main__() -> i32;
            }
            // SAFETY: user-defined entry point, linked by Map2Check instrumentation.
            unsafe { __map2check_main__() }
        },
        0,
    )
}

fn read_bytes(n: usize) -> Option<&'static [u8]> {
    let cursor = FUZZER_CURSOR.load(Ordering::SeqCst);
    let size = FUZZER_SIZE.load(Ordering::SeqCst);
    let end = match cursor.checked_add(n) {
        Some(end) if end <= size => end,
        _ => return None,
    };

    let ptr = FUZZER_DATA.load(Ordering::SeqCst);
    if ptr.is_null() {
        return None;
    }

    // SAFETY: FUZZER_DATA was set from a valid LibFuzzer buffer; cursor+n <= size.
    let slice = unsafe { std::slice::from_raw_parts(ptr.add(cursor), n) };
    FUZZER_CURSOR.store(end, Ordering::SeqCst);
    Some(slice)
}

fn read_u8() -> u8 {
    read_bytes(1).map(|b| b[0]).unwrap_or(0)
}

fn read_u32() -> u32 {
    read_bytes(4)
        .map(|b| u32::from_le_bytes(b.try_into().unwrap_or([0; 4])))
        .unwrap_or(0)
}

fn read_u64() -> u64 {
    read_bytes(8)
        .map(|b| u64::from_le_bytes(b.try_into().unwrap_or([0; 8])))
        .unwrap_or(0)
}

// ── Public nondet generators ─────────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_bool() -> bool {
    crate::ffi::ffi_guard(|| read_u8() % 2 == 0, false)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_char() -> i8 {
    crate::ffi::ffi_guard(|| read_u8() as i8, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uchar() -> u8 {
    crate::ffi::ffi_guard(read_u8, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_short() -> i16 {
    crate::ffi::ffi_guard(
        || {
            read_bytes(2)
                .map(|b| i16::from_le_bytes(b.try_into().unwrap_or([0; 2])))
                .unwrap_or(0)
        },
        0,
    )
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ushort() -> u16 {
    crate::ffi::ffi_guard(
        || {
            read_bytes(2)
                .map(|b| u16::from_le_bytes(b.try_into().unwrap_or([0; 2])))
                .unwrap_or(0)
        },
        0,
    )
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_int() -> i32 {
    crate::ffi::ffi_guard(|| read_u32() as i32, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uint() -> u32 {
    crate::ffi::ffi_guard(read_u32, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_long() -> i64 {
    crate::ffi::ffi_guard(|| read_u64() as i64, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ulong() -> u64 {
    crate::ffi::ffi_guard(read_u64, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_float() -> f32 {
    // Uses f32::from_bits — replaces C union FloatPattern type-punning safely
    crate::ffi::ffi_guard(|| f32::from_bits(read_u32()), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_double() -> f64 {
    // Uses f64::from_bits — replaces C union DoublePattern type-punning safely
    crate::ffi::ffi_guard(|| f64::from_bits(read_u64()), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_size_t() -> usize {
    crate::ffi::ffi_guard(|| read_u64() as usize, 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_pointer() -> *mut std::ffi::c_void {
    // Constructing a pointer value from an integer is safe; only
    // dereferencing it would be unsafe, and nothing here dereferences it.
    crate::ffi::ffi_guard(
        || read_u64() as usize as *mut std::ffi::c_void,
        std::ptr::null_mut(),
    )
}

// ── SV-COMP verifier primitives ──────────────────────────────────────────────
//
// Design note (documented per the project convention of registering
// trade-offs where they are made): LibFuzzer runs many inputs within a
// single process, and this crate builds with `panic = "abort"` in release
// (see Cargo.toml), so there is no portable way to unwind out of an
// arbitrarily deep call stack back to `LLVMFuzzerTestOneInput` when an
// assumption is violated. Following the same convention used by SV-COMP's
// native/concrete-execution harnesses, `__VERIFIER_assume` ends the current
// process with exit code 0 (treated as "uninteresting", not a crash) instead
// of unwinding. This does end the fuzzing campaign for the current process —
// an accepted limitation, see docs/api-deltas.md. Full symbolic-execution
// semantics (e.g. path pruning under KLEE) is out of scope for M3 and is
// deferred to the M4 KLEE spike.

/// Ends the process with exit code 0 (treated as "uninteresting", not a
/// crash) when `condition` is false. See the design note above.
#[no_mangle]
pub extern "C" fn __VERIFIER_assume(condition: i32) {
    crate::ffi::ffi_guard(
        || {
            if condition == 0 {
                std::process::exit(0);
            }
        },
        (),
    );
}

/// Fuzzer-specific alias of `__VERIFIER_assume`, matching the legacy
/// `map2check_fuzzer_assume` entry point used by the LibFuzzer nondet
/// generator. See `__VERIFIER_assume` for the exit(0) design note.
#[no_mangle]
pub extern "C" fn map2check_fuzzer_assume(condition: i32) {
    __VERIFIER_assume(condition);
}

/// SV-COMP reachability primitive: records a `Reachability` violation and
/// aborts the process. Reaching this function at runtime means the property
/// being checked was violated; it never returns.
#[no_mangle]
pub extern "C" fn __VERIFIER_error() {
    crate::ffi::ffi_guard(
        || {
            if let Err(e) = crate::state::with_state(|s| {
                s.set_false(
                    crate::caller::ViolatedProperty::Reachability,
                    0,
                    "__VERIFIER_error",
                );
                crate::output::print_json(s)
            }) {
                eprintln!("[map2check] error: {e}");
            }
        },
        (),
    );
    std::process::abort();
}

/// SV-COMP assert primitive: calls `__VERIFIER_error()` (and thus aborts)
/// when `condition` is false; otherwise a no-op.
#[no_mangle]
pub extern "C" fn __VERIFIER_assert(condition: i32) {
    crate::ffi::ffi_guard(
        || {
            if condition == 0 {
                __VERIFIER_error();
            }
        },
        (),
    );
}

//lv
// Cria uma função "falsa" apenas para os testes passarem no Linker
#[cfg(test)]
#[no_mangle]
pub extern "C" fn __map2check_main__() -> i32 {
    0 // Retorna 0 (sucesso) e não faz nada
}

#[cfg(test)]
mod tests {
    use super::*;

    // NOTE: only the non-terminating branches are unit-tested here.
    // `__VERIFIER_assume(0)`, `__VERIFIER_assert(0)` and `__VERIFIER_error()`
    // call `std::process::exit`/`std::process::abort`, which would kill the
    // whole `cargo test` binary (and every other test running in it) rather
    // than fail a single test. Those branches are instead exercised as a
    // separate process by `tests/ffi_harness.c`.

    #[test]
    fn verifier_nondet_pointer_does_not_panic() {
        let _ = __VERIFIER_nondet_pointer();
    }

    #[test]
    fn verifier_assume_true_is_a_no_op() {
        __VERIFIER_assume(1);
    }

    #[test]
    fn verifier_assert_true_is_a_no_op() {
        __VERIFIER_assert(1);
    }

    #[test]
    fn map2check_fuzzer_assume_true_is_a_no_op() {
        map2check_fuzzer_assume(1);
    }
}
