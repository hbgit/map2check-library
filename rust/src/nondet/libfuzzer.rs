// SPDX-License-Identifier: GPL-3.0-only
//
// LibFuzzer nondeterministic value generation.
// Replaces nondet_gen_libfuzzer.c — eliminates all union type-punning
// by using f32::from_bits() / f64::from_bits() from safe Rust.

use std::sync::atomic::{AtomicPtr, AtomicUsize, Ordering};

static FUZZER_CURSOR: AtomicUsize = AtomicUsize::new(0);
static FUZZER_SIZE: AtomicUsize = AtomicUsize::new(0);
static FUZZER_DATA: AtomicPtr<u8> = AtomicPtr::new(std::ptr::null_mut());

struct FuzzerStateReset;

impl Drop for FuzzerStateReset {
    fn drop(&mut self) {
        FUZZER_DATA.store(std::ptr::null_mut(), Ordering::SeqCst);
        FUZZER_SIZE.store(0, Ordering::SeqCst);
        FUZZER_CURSOR.store(0, Ordering::SeqCst);
    }
}

/// Called by LibFuzzer before the test target runs.
///
/// # Safety
/// `data` must remain valid for the duration of one fuzzer iteration.
/// This is guaranteed by the LibFuzzer runtime contract.
#[no_mangle]
pub unsafe extern "C" fn LLVMFuzzerTestOneInput(data: *const u8, size: usize) -> i32 {
    let _reset = FuzzerStateReset;
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
// single process, and an assumption is violated arbitrarily deep in a call
// stack that began at `LLVMFuzzerTestOneInput`. There is no portable way to
// unwind out of it: the entry point is `extern "C"`, and a Rust panic must
// not cross an FFI boundary regardless of the release profile's panic
// strategy, so an unwind-based `assume` would be unsound rather than merely
// awkward. Following the same convention used by SV-COMP's
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
    // Runs the per-test hook (if any); otherwise succeeds and does nothing.
    let hook = *TEST_MAIN_HOOK
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner);
    if let Some(hook) = hook {
        hook();
    }
    0
}

/// Body of the fake `__map2check_main__`, installed by a test while it holds
/// the global test lock.
#[cfg(test)]
static TEST_MAIN_HOOK: std::sync::Mutex<Option<fn()>> = std::sync::Mutex::new(None);

#[cfg(test)]
mod tests {
    use super::*;

    // NOTE: the branches that end the process (`exit(0)` / `abort()`) would
    // kill the whole `cargo test` binary if called in-process. They are
    // tested at the end of this module by re-running this test binary as a
    // child process; `tests/ffi_harness.c` also exercises them.

    #[test]
    fn verifier_nondet_pointer_does_not_panic() {
        let _guard = crate::state::test_lock();
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

    /// Installs `data` as the current fuzzer input for the duration of `f`,
    /// under the global test lock, and clears it afterwards.
    fn with_input<R>(data: &[u8], f: impl FnOnce() -> R) -> R {
        let _guard = crate::state::test_lock();
        let _reset = FuzzerStateReset;
        FUZZER_DATA.store(data.as_ptr() as *mut u8, Ordering::SeqCst);
        FUZZER_SIZE.store(data.len(), Ordering::SeqCst);
        FUZZER_CURSOR.store(0, Ordering::SeqCst);
        f()
    }

    #[test]
    fn narrow_generators_decode_little_endian_input_in_order() {
        let data = [
            0x02, // bool: 2 % 2 == 0 -> true
            0xff, // char: -1
            0xfe, // uchar: 254
            0x01, 0x80, // short: 0x8001 -> -32767
            0x34, 0x12, // ushort: 0x1234
            0xff, 0xff, 0xff, 0xff, // int: -1
            0x78, 0x56, 0x34, 0x12, // uint: 0x1234_5678
        ];
        with_input(&data, || {
            assert!(__VERIFIER_nondet_bool());
            assert_eq!(__VERIFIER_nondet_char(), -1);
            assert_eq!(__VERIFIER_nondet_uchar(), 254);
            assert_eq!(__VERIFIER_nondet_short(), -32767);
            assert_eq!(__VERIFIER_nondet_ushort(), 0x1234);
            assert_eq!(__VERIFIER_nondet_int(), -1);
            assert_eq!(__VERIFIER_nondet_uint(), 0x1234_5678);
        });
    }

    #[test]
    fn wide_generators_decode_eight_byte_values() {
        let mut data = Vec::new();
        data.extend_from_slice(&(-2_i64).to_le_bytes());
        data.extend_from_slice(&u64::MAX.to_le_bytes());
        data.extend_from_slice(&1.5_f32.to_bits().to_le_bytes());
        data.extend_from_slice(&(-2.25_f64).to_bits().to_le_bytes());
        data.extend_from_slice(&4096_u64.to_le_bytes());
        data.extend_from_slice(&0x1000_u64.to_le_bytes());
        with_input(&data, || {
            assert_eq!(__VERIFIER_nondet_long(), -2);
            assert_eq!(__VERIFIER_nondet_ulong(), u64::MAX);
            assert_eq!(__VERIFIER_nondet_float().to_bits(), 1.5_f32.to_bits());
            assert_eq!(__VERIFIER_nondet_double().to_bits(), (-2.25_f64).to_bits());
            assert_eq!(__VERIFIER_nondet_size_t(), 4096);
            assert_eq!(__VERIFIER_nondet_pointer() as usize, 0x1000);
        });
    }

    #[test]
    fn exhausted_input_yields_zero_without_advancing() {
        with_input(&[0x07], || {
            assert_eq!(__VERIFIER_nondet_int(), 0); // needs 4 bytes, only 1 left
            assert_eq!(__VERIFIER_nondet_uchar(), 7); // failed read did not consume
            assert_eq!(__VERIFIER_nondet_uchar(), 0);
            assert!(__VERIFIER_nondet_bool()); // 0 % 2 == 0
        });
    }

    #[test]
    fn null_buffer_with_nonzero_size_yields_zero() {
        let _guard = crate::state::test_lock();
        let _reset = FuzzerStateReset;
        FUZZER_SIZE.store(8, Ordering::SeqCst);
        assert_eq!(__VERIFIER_nondet_long(), 0);
    }

    #[test]
    fn fuzzer_iteration_resets_analysis_state_and_input() {
        let _guard = crate::state::test_lock();
        crate::state::with_state(|s| {
            s.set_false(crate::caller::ViolatedProperty::Overflow, 7, "stale");
            Ok(())
        })
        .unwrap();
        let data = [1_u8, 2, 3, 4];
        // SAFETY: `data` is valid for `data.len()` bytes for the whole call.
        let rc = unsafe { LLVMFuzzerTestOneInput(data.as_ptr(), data.len()) };
        assert_eq!(rc, 0);
        assert!(crate::state::with_state(|s| Ok(s.result.ok)).unwrap());
        assert!(FUZZER_DATA.load(Ordering::SeqCst).is_null());
        assert_eq!(FUZZER_SIZE.load(Ordering::SeqCst), 0);
        assert_eq!(FUZZER_CURSOR.load(Ordering::SeqCst), 0);
    }

    /// Fake program body: tracks one allocation and one nondet value, and
    /// records the first byte of its input.
    fn iteration_body() {
        // SAFETY: fake addresses are only stored, never dereferenced.
        unsafe { crate::ffi::map2check_map_malloc(0x1000 as *const _, 8) };
        let _ = __VERIFIER_nondet_uchar();
        let first = crate::state::with_state(|s| {
            s.nondets.push(crate::nondet::NonDetEntry::new(
                1,
                1,
                0,
                "main",
                crate::nondet::NonDetValue::Int(7),
            ));
            Ok(s.current_step())
        })
        .unwrap();
        ITERATION_STEPS.fetch_add(first as usize, Ordering::SeqCst);
    }

    static ITERATION_STEPS: AtomicUsize = AtomicUsize::new(0);

    fn set_hook(hook: Option<fn()>) {
        *TEST_MAIN_HOOK.lock().unwrap() = hook;
    }

    #[test]
    fn two_fuzzer_iterations_yield_independent_results() {
        let _guard = crate::state::test_lock();
        set_hook(Some(iteration_body));
        ITERATION_STEPS.store(0, Ordering::SeqCst);

        let first = [0xAA_u8, 1, 2];
        // SAFETY: buffers are valid for their lengths for the whole call.
        unsafe { LLVMFuzzerTestOneInput(first.as_ptr(), first.len()) };
        // Dirty the state between iterations as a crashed/violating run would.
        crate::state::with_state(|s| {
            s.set_false(crate::caller::ViolatedProperty::Overflow, 9, "first");
            s.next_step();
            Ok(())
        })
        .unwrap();
        let second = [0xBB_u8];
        // SAFETY: as above.
        unsafe { LLVMFuzzerTestOneInput(second.as_ptr(), second.len()) };
        set_hook(None);

        crate::state::with_state(|s| {
            assert!(s.result.ok, "first-run violation leaked into the second");
            assert_eq!(s.result.line, 0);
            assert!(s.result.function_name.is_empty());
            // The second body ran one step-counting call (nondet_uchar) itself.
            assert_eq!(s.current_step(), 1, "step counter leaked");
            assert_eq!(s.memtrack.len(), 1, "first-run allocation leaked");
            assert_eq!(s.nondets.len(), 1, "first-run nondet log leaked");
            Ok(())
        })
        .unwrap();
        assert_eq!(FUZZER_CURSOR.load(Ordering::SeqCst), 0);
    }

    #[test]
    fn fuzzer_iteration_rejects_null_data_with_nonzero_size() {
        let _guard = crate::state::test_lock();
        // SAFETY: the entry point must reject a null buffer with non-zero size
        // without reading from it; nothing is dereferenced.
        let rc = unsafe { LLVMFuzzerTestOneInput(std::ptr::null(), 16) };
        assert_eq!(rc, 0);
        assert!(FUZZER_DATA.load(Ordering::SeqCst).is_null());
    }

    // ── Process-terminating branches (issue #29) ─────────────────────────────
    //
    // Each `*_child` test only does something when `CHILD_ENV` is set: the
    // parent test re-runs this same test binary filtered to that one child and
    // inspects how the child process ended.

    const CHILD_ENV: &str = "MAP2CHECK_FFI_CHILD";
    const STARTED: &str = "map2check-child-started";
    const SURVIVED: &str = "map2check-child-survived";

    fn is_child() -> bool {
        std::env::var_os(CHILD_ENV).is_some()
    }

    /// Runs `nondet::libfuzzer::tests::<name>` in a separate process.
    fn run_child(name: &str) -> std::process::Output {
        let exe = std::env::current_exe().unwrap();
        let output = std::process::Command::new(exe)
            .args(["--exact", &format!("nondet::libfuzzer::tests::{name}")])
            .args(["--nocapture", "--test-threads=1"])
            .env(CHILD_ENV, "1")
            .output()
            .unwrap();
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            stdout.contains(STARTED),
            "o processo filho não rodou `{name}`:\n{stdout}"
        );
        assert!(
            !stdout.contains(SURVIVED),
            "`{name}` deveria ter encerrado o processo:\n{stdout}"
        );
        output
    }

    /// Asserts the child ended via `exit(0)` before libtest printed its summary.
    fn assert_exited_zero(output: &std::process::Output) {
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(output.status.code(), Some(0), "{stdout}");
        assert!(!stdout.contains("test result:"), "{stdout}");
    }

    /// Asserts the child aborted after printing a REACHABILITY report.
    fn assert_aborted_with_reachability(output: &std::process::Output) {
        use std::os::unix::process::ExitStatusExt;
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(
            output.status.signal(),
            Some(6),
            "esperava SIGABRT:\n{stdout}"
        );
        assert!(stdout.contains("REACHABILITY"), "{stdout}");
    }

    #[test]
    fn verifier_assume_false_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_assume(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn verifier_assume_false_exits_with_zero() {
        assert_exited_zero(&run_child("verifier_assume_false_child"));
    }

    #[test]
    fn map2check_fuzzer_assume_false_child() {
        if is_child() {
            println!("{STARTED}");
            map2check_fuzzer_assume(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn map2check_fuzzer_assume_false_exits_with_zero() {
        assert_exited_zero(&run_child("map2check_fuzzer_assume_false_child"));
    }

    #[test]
    fn verifier_error_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_error();
            #[allow(unreachable_code)]
            {
                println!("{SURVIVED}");
            }
        }
    }

    #[test]
    fn verifier_error_aborts_and_reports_reachability() {
        assert_aborted_with_reachability(&run_child("verifier_error_child"));
    }

    #[test]
    fn verifier_assert_false_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_assert(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn verifier_assert_false_aborts_and_reports_reachability() {
        assert_aborted_with_reachability(&run_child("verifier_assert_false_child"));
    }
}
