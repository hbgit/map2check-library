// SPDX-License-Identifier: GPL-3.0-only
//
// LibFuzzer nondeterministic value generation.
// Replaces nondet_gen_libfuzzer.c — eliminates all union type-punning
// by using f32::from_bits() / f64::from_bits() from safe Rust.
//
// Input semantics are those of Map2Check develop's AFL++ generator
// (`modules/backend/library/lib/NonDetGeneratorAFL.c`), which D1 conditions
// 4 and 9 require (docs/cutover/decisoes.md):
//
// - each value takes `sizeof(type)` bytes of the input, in order, copied
//   into the value in memory order (`get_bytes_from_afl`, :67-74, and the
//   generators, :76-99): little-endian on x86-64, the layout KLEE writes
//   into a `.ktest` for `klee_make_symbolic(&v, sizeof v)`;
// - past the end of the input the reader rewinds (`get_next_input_from_afl`,
//   :55-62): the read that finds the index at the end returns `data[0]`
//   without advancing, so after every wrap `data[0]` is read twice;
// - `pchar` reads an `unsigned` length, returns NULL for 0, caps it at 4096,
//   and fills `length - 1` chars plus a NUL (:101-118);
// - a failed `__VERIFIER_assume` abandons the current input and the loop
//   moves on to the next one (`nondet_cancel`/`setjmp`, :31-37, :171-184).

use std::sync::atomic::{AtomicBool, AtomicPtr, AtomicUsize, Ordering};

static FUZZER_CURSOR: AtomicUsize = AtomicUsize::new(0);
static FUZZER_SIZE: AtomicUsize = AtomicUsize::new(0);
static FUZZER_DATA: AtomicPtr<u8> = AtomicPtr::new(std::ptr::null_mut());
/// True while `LLVMFuzzerTestOneInput` runs the program for one input.
///
/// Process-wide, not per thread: a program thread that calls
/// `__VERIFIER_assume(0)` while an iteration runs on another thread unwinds
/// a stack with no `catch_unwind` on it, and the process aborts. Develop's
/// cross-thread `longjmp` is undefined as well; the fuzzer drives the
/// program on one thread.
static ITERATION_ACTIVE: AtomicBool = AtomicBool::new(false);

struct FuzzerStateReset;

impl Drop for FuzzerStateReset {
    fn drop(&mut self) {
        ITERATION_ACTIVE.store(false, Ordering::SeqCst);
        FUZZER_DATA.store(std::ptr::null_mut(), Ordering::SeqCst);
        FUZZER_SIZE.store(0, Ordering::SeqCst);
        FUZZER_CURSOR.store(0, Ordering::SeqCst);
    }
}

/// Unwind payload of a failed `__VERIFIER_assume` inside an iteration: the
/// Rust counterpart of develop's `longjmp(map2check_reject_env, 1)`.
struct InputRejected;

/// Called by LibFuzzer (or AFL++'s libFuzzer driver) once per input.
///
/// A failed `__VERIFIER_assume` ends the iteration early, as develop's
/// `nondet_cancel` does: it unwinds to this function, which returns 0 so the
/// fuzzer goes on with the next input. The analysis state is reset at the
/// start of every iteration (#9), so the abandoned one leaves nothing behind.
///
/// # Safety
/// `data` must remain valid for the duration of one fuzzer iteration.
/// This is guaranteed by the LibFuzzer runtime contract.
#[no_mangle]
pub unsafe extern "C" fn LLVMFuzzerTestOneInput(data: *const u8, size: usize) -> i32 {
    let _reset = FuzzerStateReset;
    let started = crate::ffi::ffi_guard(
        || {
            crate::state::reset();
            if data.is_null() && size != 0 {
                return false;
            }
            // SAFETY: LibFuzzer guarantees `data` is valid for `size` bytes.
            FUZZER_DATA.store(data as *mut u8, Ordering::SeqCst);
            FUZZER_SIZE.store(size, Ordering::SeqCst);
            FUZZER_CURSOR.store(0, Ordering::SeqCst);
            ITERATION_ACTIVE.store(true, Ordering::SeqCst);
            true
        },
        false,
    );
    if !started {
        return 0;
    }
    unsafe extern "C-unwind" {
        /// The analysed program's `main`, renamed by the Map2Check pass.
        /// `C-unwind`: a failed `__VERIFIER_assume` unwinds out of it.
        fn __map2check_main__() -> i32;
    }
    // SAFETY: user-defined entry point, linked by Map2Check instrumentation.
    let run = std::panic::catch_unwind(|| unsafe { __map2check_main__() });
    if let Err(payload) = run {
        if !payload.is::<InputRejected>() {
            eprintln!("[map2check] panic in FFI boundary; recovering safely");
        }
    }
    0
}

/// Fills `N` bytes from the input as develop's `get_bytes_from_afl` does,
/// one `get_next_input_from_afl` per byte. With no input (no iteration, or an
/// empty one) every byte is 0: develop would read `data[0]` of an empty
/// buffer, out of bounds.
fn read_value<const N: usize>() -> [u8; N] {
    let mut out = [0_u8; N];
    let ptr = FUZZER_DATA.load(Ordering::Relaxed);
    let size = FUZZER_SIZE.load(Ordering::Relaxed);
    if ptr.is_null() || size == 0 {
        return out;
    }
    // SAFETY: FUZZER_DATA was set from a valid LibFuzzer buffer of `size`
    // bytes, which stays valid for the whole iteration.
    let data = unsafe { std::slice::from_raw_parts(ptr, size) };
    let mut index = FUZZER_CURSOR.load(Ordering::Relaxed);
    for byte in &mut out {
        if index < size {
            *byte = data[index];
            index += 1;
        } else {
            index = 0;
            *byte = data[0];
        }
    }
    FUZZER_CURSOR.store(index, Ordering::Relaxed);
    out
}

// ── Public nondet generators ─────────────────────────────────────────────────

/// develop's `bool` is `typedef int bool` (`NonDetGenerator.h:74`): four
/// bytes, returned as that `int` converted to `_Bool`.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_bool() -> bool {
    crate::ffi::ffi_guard(|| i32::from_ne_bytes(read_value()) != 0, false)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_char() -> i8 {
    crate::ffi::ffi_guard(|| <i8>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uchar() -> u8 {
    crate::ffi::ffi_guard(|| <u8>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_short() -> i16 {
    crate::ffi::ffi_guard(|| <i16>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ushort() -> u16 {
    crate::ffi::ffi_guard(|| <u16>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_int() -> i32 {
    crate::ffi::ffi_guard(|| <i32>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uint() -> u32 {
    crate::ffi::ffi_guard(|| <u32>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_long() -> i64 {
    crate::ffi::ffi_guard(|| <i64>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ulong() -> u64 {
    crate::ffi::ffi_guard(|| <u64>::from_ne_bytes(read_value()), 0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_size_t() -> usize {
    crate::ffi::ffi_guard(|| <usize>::from_ne_bytes(read_value()), 0)
}

/// glibc's `loff_t` is `long long`.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_loff_t() -> i64 {
    crate::ffi::ffi_guard(|| <i64>::from_ne_bytes(read_value()), 0)
}

/// develop: `#define sector_t unsigned long` (`NonDetGenerator.h:112`).
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_sector_t() -> std::os::raw::c_ulong {
    crate::ffi::ffi_guard(|| <std::os::raw::c_ulong>::from_ne_bytes(read_value()), 0)
}

/// Four bytes, like `int`; develop has no `float` generator.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_float() -> f32 {
    // Uses f32::from_bits — replaces C union FloatPattern type-punning safely
    crate::ffi::ffi_guard(|| f32::from_bits(u32::from_ne_bytes(read_value())), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_double() -> f64 {
    // Uses f64::from_bits — replaces C union DoublePattern type-punning safely
    crate::ffi::ffi_guard(|| f64::from_bits(u64::from_ne_bytes(read_value())), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_pointer() -> *mut std::ffi::c_void {
    // Constructing a pointer value from an integer is safe; only
    // dereferencing it would be unsafe, and nothing here dereferences it.
    crate::ffi::ffi_guard(
        || usize::from_ne_bytes(read_value()) as *mut std::ffi::c_void,
        std::ptr::null_mut(),
    )
}

/// develop's `MAP2CHECK_MAX_FUZZED_STRING` (`NonDetGeneratorAFL.c:101`).
const MAX_FUZZED_STRING: u32 = 4096;

/// A NUL-terminated string from the input, allocated with the C `malloc` so
/// the program can `free` it (`NonDetGeneratorAFL.c:103-118`): an
/// `unsigned` length, NULL when it is 0 (or when `malloc` fails), capped at
/// 4096, then `length - 1` chars, each read like `__VERIFIER_nondet_char`.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_pchar() -> *mut std::os::raw::c_char {
    extern "C" {
        fn malloc(size: usize) -> *mut std::ffi::c_void;
    }
    crate::ffi::ffi_guard(
        || {
            let length = u32::from_ne_bytes(read_value()).min(MAX_FUZZED_STRING) as usize;
            if length == 0 {
                return std::ptr::null_mut();
            }
            // SAFETY: plain C allocation; the result is checked for NULL.
            let string = unsafe { malloc(length) }.cast::<u8>();
            if string.is_null() {
                return std::ptr::null_mut();
            }
            // SAFETY: `string` holds `length` bytes, written once each below.
            let bytes = unsafe { std::slice::from_raw_parts_mut(string, length) };
            let (chars, nul) = bytes.split_at_mut(length - 1);
            for c in chars {
                *c = u8::from_ne_bytes(read_value());
            }
            nul[0] = 0;
            string.cast()
        },
        std::ptr::null_mut(),
    )
}

// ── SV-COMP verifier primitives ──────────────────────────────────────────────
//
// `__VERIFIER_assume(0)` inside a fuzzer iteration abandons that input, as
// develop's `nondet_assume` → `nondet_cancel` → `longjmp` back to the
// `__AFL_LOOP` does (NonDetGeneratorAFL.c:31-37, :171-184): no exit, no
// abort, and the next input runs in the same process.
//
// Mechanism (design note): a `longjmp` from Rust back to a `setjmp` would
// need the `setjmp` in C (Rust cannot call `setjmp` soundly, it returns
// twice) and would skip Rust frames, which is only defined when none of
// them has a destructor; `LLVMFuzzerTestOneInput` owns a drop guard. Instead
// the assume unwinds with `std::panic::resume_unwind` (no panic hook, no
// message) and `LLVMFuzzerTestOneInput` catches it with `catch_unwind`.
// Every Rust function on that path is declared `C-unwind`
// (`__VERIFIER_assume`, `map2check_fuzzer_assume`, the `__map2check_main__`
// import), which is the defined way for a Rust unwind to cross C frames
// (RFC 2945). The C frames in between are the analysed program's. clang
// marks C functions `nounwind` unless the program is compiled with
// `-fexceptions`, and unwinding out of a `nounwind` function is undefined
// in LLVM IR; without `-fexceptions` the unwind only works because x86-64
// Linux emits `.eh_frame` by default, and with no unwind tables at all it
// aborts ("failed to initiate panic"). D1 condition 11 therefore requires
// the pipeline to compile the program with `-fexceptions` (Task 3.2). Plain
// C frames hold no cleanups, so the unwind skips what develop's `longjmp`
// skips; a frame with `__attribute__((cleanup))` compiled with
// `-fexceptions` would have its cleanup run, which `longjmp` would skip.
// The unwind needs
// `panic = "unwind"` (the `runtime` and `release` profiles); built with
// `panic = "abort"` the library keeps the exit(0) fallback below.
//
// Outside an iteration (no `LLVMFuzzerTestOneInput` on the stack, e.g. a
// program that links the library without a fuzzer driver),
// `__VERIFIER_assume(0)` keeps ending the process with exit code 0, the
// SV-COMP convention for an infeasible path (SD-07).

/// Abandons the current fuzzer input, or ends the process with exit code 0
/// when there is none. Never returns.
fn reject_input() -> ! {
    #[cfg(panic = "unwind")]
    if ITERATION_ACTIVE.load(Ordering::SeqCst) {
        std::panic::resume_unwind(Box::new(InputRejected));
    }
    std::process::exit(0);
}

/// Abandons the current fuzzer input when `condition` is false (see the
/// design note above); outside an iteration, ends the process with exit 0.
#[no_mangle]
pub extern "C-unwind" fn __VERIFIER_assume(condition: i32) {
    // The decision runs under ffi_guard; the unwind must not, or ffi_guard
    // would catch it.
    if crate::ffi::ffi_guard(|| condition == 0, false) {
        reject_input();
    }
}

/// Fuzzer-specific alias of `__VERIFIER_assume`, matching the legacy
/// `map2check_fuzzer_assume` entry point used by the LibFuzzer nondet
/// generator.
#[no_mangle]
pub extern "C-unwind" fn map2check_fuzzer_assume(condition: i32) {
    if crate::ffi::ffi_guard(|| condition == 0, false) {
        reject_input();
    }
}

/// SV-COMP reachability primitive. With an analysis mode set it does
/// nothing, as in develop: the target pass reports reachability through
/// `map2check_reach_target`. With the mode unset it records a
/// `Reachability` violation, prints the JSON report and aborts (SD-08).
#[no_mangle]
pub extern "C" fn __VERIFIER_error() {
    if crate::ffi::ffi_guard(super::record_verifier_error, false) {
        std::process::abort();
    }
}

/// SV-COMP assert primitive: calls `__VERIFIER_error()` when `condition`
/// is false, which with an analysis mode set does nothing (develop's
/// `__VERIFIER_assert` is empty; the assert pass emits
/// `map2check_is_valid_assert`) and with none aborts (SD-08).
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
pub extern "C-unwind" fn __map2check_main__() -> i32 {
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

    // ── Input byte layout (D1 conditions 4 and 9) ───────────────────────────
    //
    // develop's NonDetGeneratorAFL.c copies sizeof(type) bytes per value, in
    // memory order, into the value (`get_bytes_from_afl`, :67-74; the
    // generators, :76-99), so a value is the little-endian reading of its
    // bytes on x86-64. Past the end of the input `get_next_input_from_afl`
    // (:55-62) rewinds: the read that finds the index at the end returns
    // data[0] WITHOUT advancing, so data[0] is read twice after every wrap.

    /// develop's `get_next_input_from_afl`, transcribed: the bytes `count`
    /// reads return from a fresh input.
    fn develop_stream(data: &[u8], count: usize) -> Vec<u8> {
        let mut index = 0;
        (0..count)
            .map(|_| {
                if index < data.len() {
                    index += 1;
                    data[index - 1]
                } else {
                    index = 0;
                    data[0]
                }
            })
            .collect()
    }

    #[test]
    fn develop_stream_model_rewinds_and_repeats_the_first_byte() {
        // Hand-checked against NonDetGeneratorAFL.c:55-62.
        assert_eq!(develop_stream(&[1, 2], 7), [1, 2, 1, 1, 2, 1, 1]);
        assert_eq!(develop_stream(&[0x41], 4), [0x41; 4]);
    }

    /// Reads two values with `$gen` from `data` and checks them against the
    /// bytes develop's reader returns for the same input.
    macro_rules! layout_case {
        ($gen:ident, $ty:ty, $data:expr) => {{
            let data: &[u8] = $data;
            let size = std::mem::size_of::<$ty>();
            with_input(data, || {
                let first: $ty = $gen();
                let second: $ty = $gen();
                let stream = develop_stream(data, 2 * size);
                let expect_first = <$ty>::from_ne_bytes(stream[..size].try_into().unwrap());
                let expect_second = <$ty>::from_ne_bytes(stream[size..].try_into().unwrap());
                assert_eq!(
                    first.to_ne_bytes(),
                    expect_first.to_ne_bytes(),
                    "{}: primeiro valor de {data:02x?}",
                    stringify!($gen)
                );
                assert_eq!(
                    second.to_ne_bytes(),
                    expect_second.to_ne_bytes(),
                    "{}: segundo valor de {data:02x?}",
                    stringify!($gen)
                );
            });
        }};
    }

    /// Short input (fewer bytes than the type), exact-size input, and a
    /// second value that spans the wrap, for one generator.
    macro_rules! layout_cases {
        ($gen:ident, $ty:ty) => {{
            let size = std::mem::size_of::<$ty>();
            let bytes: Vec<u8> = (1..=2 * size as u8 + 3)
                .map(|b| b.wrapping_mul(0x11))
                .collect();
            // shorter than the type (one byte when the type has one byte)
            layout_case!($gen, $ty, &bytes[..size.saturating_sub(1).max(1)]);
            // exactly the type: the second value is all wrap
            layout_case!($gen, $ty, &bytes[..size]);
            // the second value starts inside the input and wraps
            layout_case!($gen, $ty, &bytes[..size + size / 2 + 1]);
        }};
    }

    #[test]
    fn every_generator_reads_sizeof_type_bytes_and_wraps_like_develop() {
        layout_cases!(__VERIFIER_nondet_char, i8);
        layout_cases!(__VERIFIER_nondet_uchar, u8);
        layout_cases!(__VERIFIER_nondet_short, i16);
        layout_cases!(__VERIFIER_nondet_ushort, u16);
        layout_cases!(__VERIFIER_nondet_int, i32);
        layout_cases!(__VERIFIER_nondet_uint, u32);
        layout_cases!(__VERIFIER_nondet_long, i64);
        layout_cases!(__VERIFIER_nondet_ulong, u64);
        layout_cases!(__VERIFIER_nondet_size_t, usize);
        layout_cases!(__VERIFIER_nondet_loff_t, i64);
        layout_cases!(__VERIFIER_nondet_sector_t, std::os::raw::c_ulong);
        layout_cases!(nondet_float_bits, u32);
        layout_cases!(nondet_double_bits, u64);
        layout_cases!(nondet_pointer_bits, usize);
    }

    fn nondet_float_bits() -> u32 {
        __VERIFIER_nondet_float().to_bits()
    }

    fn nondet_double_bits() -> u64 {
        __VERIFIER_nondet_double().to_bits()
    }

    fn nondet_pointer_bits() -> usize {
        __VERIFIER_nondet_pointer() as usize
    }

    #[test]
    fn seed_a_reads_0x41414141_like_develop() {
        // The spike's seed (`printf A`): develop reads x = 0x41414141, which
        // CmpLog can match against the input (D1 condition 4).
        with_input(b"A", || assert_eq!(__VERIFIER_nondet_int(), 0x4141_4141));
        with_input(&[0x2a, 0, 0, 0], || assert_eq!(__VERIFIER_nondet_int(), 42));
    }

    #[test]
    fn bool_consumes_four_bytes_and_is_the_int_converted_to_bool() {
        with_input(&[0, 0, 0, 0, 0, 1, 0, 0, 7], || {
            assert!(!__VERIFIER_nondet_bool()); // 0x00000000
            assert!(__VERIFIER_nondet_bool()); // 0x00000100: low byte 0, int != 0
            assert_eq!(__VERIFIER_nondet_uchar(), 7); // the ninth byte
        });
        // short inputs wrap: 00 00 00 00 and 00 01 00 00
        with_input(&[0], || assert!(!__VERIFIER_nondet_bool()));
        with_input(&[0, 1], || assert!(__VERIFIER_nondet_bool()));
    }

    #[test]
    fn values_are_little_endian_in_input_order() {
        let mut data = Vec::new();
        data.extend_from_slice(&(-2_i64).to_le_bytes());
        data.extend_from_slice(&1.5_f32.to_bits().to_le_bytes());
        data.extend_from_slice(&(-2.25_f64).to_bits().to_le_bytes());
        data.extend_from_slice(&0x1000_u64.to_le_bytes());
        data.extend_from_slice(&(-32767_i16).to_le_bytes());
        with_input(&data, || {
            assert_eq!(__VERIFIER_nondet_long(), -2);
            assert_eq!(__VERIFIER_nondet_float().to_bits(), 1.5_f32.to_bits());
            assert_eq!(__VERIFIER_nondet_double().to_bits(), (-2.25_f64).to_bits());
            assert_eq!(__VERIFIER_nondet_pointer() as usize, 0x1000);
            assert_eq!(__VERIFIER_nondet_short(), -32767);
        });
    }

    #[test]
    fn empty_input_yields_zero() {
        // develop reads data[0] of an empty buffer (out of bounds); the
        // library returns zero bytes instead (semantic-deltas.md).
        with_input(&[], || {
            assert_eq!(__VERIFIER_nondet_int(), 0);
            assert_eq!(__VERIFIER_nondet_ulong(), 0);
            assert!(__VERIFIER_nondet_pchar().is_null());
        });
    }

    #[test]
    fn without_an_iteration_every_generator_yields_zero() {
        let _guard = crate::state::test_lock();
        assert!(!__VERIFIER_nondet_bool());
        assert_eq!(__VERIFIER_nondet_char(), 0);
        assert_eq!(__VERIFIER_nondet_uchar(), 0);
        assert_eq!(__VERIFIER_nondet_short(), 0);
        assert_eq!(__VERIFIER_nondet_ushort(), 0);
        assert_eq!(__VERIFIER_nondet_int(), 0);
        assert_eq!(__VERIFIER_nondet_uint(), 0);
        assert_eq!(__VERIFIER_nondet_long(), 0);
        assert_eq!(__VERIFIER_nondet_ulong(), 0);
        assert_eq!(__VERIFIER_nondet_size_t(), 0);
        assert_eq!(__VERIFIER_nondet_float().to_bits(), 0);
        assert_eq!(__VERIFIER_nondet_double().to_bits(), 0);
        assert!(__VERIFIER_nondet_pointer().is_null());
        assert_eq!(__VERIFIER_nondet_loff_t(), 0);
        assert_eq!(__VERIFIER_nondet_sector_t(), 0);
        assert!(__VERIFIER_nondet_pchar().is_null());
    }

    // ── pchar (NonDetGeneratorAFL.c:101-118) ─────────────────────────────────

    extern "C" {
        fn free(ptr: *mut std::ffi::c_void);
    }

    /// Takes a `__VERIFIER_nondet_pchar` result: its bytes up to the NUL, and
    /// frees it with the C allocator, as the analysed program would.
    fn take_pchar(p: *mut std::os::raw::c_char) -> Option<Vec<u8>> {
        if p.is_null() {
            return None;
        }
        // SAFETY: a non-null result is a NUL-terminated malloc'd string.
        let bytes = unsafe { std::ffi::CStr::from_ptr(p) }.to_bytes().to_vec();
        // SAFETY: allocated with malloc by the generator; freed once.
        unsafe { free(p.cast()) };
        Some(bytes)
    }

    #[test]
    fn pchar_reads_an_unsigned_length_then_length_minus_one_chars() {
        with_input(&[3, 0, 0, 0, b'a', b'b', b'c'], || {
            assert_eq!(take_pchar(__VERIFIER_nondet_pchar()), Some(b"ab".to_vec()));
            // the cursor is at 'c': the next generator reads it
            assert_eq!(__VERIFIER_nondet_uchar(), b'c');
        });
        with_input(&[1, 0, 0, 0], || {
            assert_eq!(take_pchar(__VERIFIER_nondet_pchar()), Some(Vec::new()));
        });
        with_input(&[0, 0, 0, 0], || {
            assert!(__VERIFIER_nondet_pchar().is_null())
        });
    }

    #[test]
    fn pchar_caps_the_length_at_4096_and_wraps_for_its_chars() {
        // length 0x41414141 > 4096: capped to 4096, 4095 chars of 'A'.
        with_input(b"A", || {
            let s = take_pchar(__VERIFIER_nondet_pchar()).unwrap();
            assert_eq!(s.len(), 4095);
            assert!(s.iter().all(|&c| c == b'A'));
        });
    }

    // ── __VERIFIER_assume inside an iteration (develop: nondet_cancel) ───────

    static AFTER_ASSUME: AtomicUsize = AtomicUsize::new(0);

    /// Fake program: tracks a block, rejects inputs whose first int is not
    /// 7 (as `nondet_assume` does with `longjmp`), and counts the runs that
    /// got past the assume.
    fn assume_body() {
        // SAFETY: fake address, only stored.
        unsafe { crate::ffi::map2check_map_malloc(0x2000 as *const _, 8) };
        let x = __VERIFIER_nondet_int();
        __VERIFIER_assume(i32::from(x == 7));
        AFTER_ASSUME.fetch_add(1, Ordering::SeqCst);
    }

    #[test]
    fn failed_assume_abandons_only_the_current_iteration() {
        let _guard = crate::state::test_lock();
        set_hook(Some(assume_body));
        AFTER_ASSUME.store(0, Ordering::SeqCst);

        let rejected = 1_i32.to_le_bytes();
        let accepted = 7_i32.to_le_bytes();
        // SAFETY: buffers are valid for their lengths for the whole call.
        let rc = unsafe { LLVMFuzzerTestOneInput(rejected.as_ptr(), rejected.len()) };
        assert_eq!(rc, 0);
        assert_eq!(AFTER_ASSUME.load(Ordering::SeqCst), 0, "assume não cortou");
        assert!(!ITERATION_ACTIVE.load(Ordering::SeqCst));
        assert!(FUZZER_DATA.load(Ordering::SeqCst).is_null());
        // The state is usable at once, as at the start of an iteration.
        assert!(crate::state::with_state(|s| Ok(s.result.ok)).is_ok());

        // SAFETY: as above.
        let rc = unsafe { LLVMFuzzerTestOneInput(accepted.as_ptr(), accepted.len()) };
        set_hook(None);
        assert_eq!(rc, 0);
        assert_eq!(AFTER_ASSUME.load(Ordering::SeqCst), 1);
        crate::state::with_state(|s| {
            assert_eq!(s.memtrack.len(), 1, "o bloco da iteração rejeitada vazou");
            Ok(())
        })
        .unwrap();
    }

    fn fuzzer_assume_body() {
        map2check_fuzzer_assume(0);
        AFTER_ASSUME.fetch_add(1, Ordering::SeqCst);
    }

    #[test]
    fn failed_fuzzer_assume_abandons_the_iteration_too() {
        let _guard = crate::state::test_lock();
        set_hook(Some(fuzzer_assume_body));
        AFTER_ASSUME.store(0, Ordering::SeqCst);
        let data = [0_u8; 4];
        for _ in 0..3 {
            // SAFETY: valid buffer for the whole call.
            assert_eq!(
                unsafe { LLVMFuzzerTestOneInput(data.as_ptr(), data.len()) },
                0
            );
        }
        set_hook(None);
        assert_eq!(AFTER_ASSUME.load(Ordering::SeqCst), 0);
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

    // With an analysis mode set (a Map2Check run), `__VERIFIER_error` and
    // `__VERIFIER_assert` do nothing, as in develop (`Map2CheckFunctions.c:57-59`,
    // `AnalysisModeAssert.c:25-27`): the passes carry the target and assert
    // checks (`map2check_reach_target`, `map2check_is_valid_assert`).

    /// Runs a child that must survive, and returns its stdout.
    fn run_surviving_child(name: &str) -> String {
        let exe = std::env::current_exe().unwrap();
        let output = std::process::Command::new(exe)
            .args(["--exact", &format!("nondet::libfuzzer::tests::{name}")])
            .args(["--nocapture", "--test-threads=1"])
            .env(CHILD_ENV, "1")
            .output()
            .unwrap();
        let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
        assert!(
            output.status.success(),
            "`{name}` não terminou bem:\n{stdout}"
        );
        assert!(
            stdout.contains(STARTED),
            "o filho não rodou `{name}`:\n{stdout}"
        );
        assert!(
            stdout.contains(SURVIVED),
            "`{name}` encerrou o processo:\n{stdout}"
        );
        stdout
    }

    fn current_property() -> crate::caller::ViolatedProperty {
        crate::ffi::get_current_property()
    }

    #[test]
    fn verifier_error_with_memtrack_mode_child() {
        if is_child() {
            println!("{STARTED}");
            crate::ffi::map2check_set_mode(1); // memtrack
            crate::ffi::map2check_init();
            __VERIFIER_error();
            __VERIFIER_assert(0);
            println!("after-error={:?}", current_property());
            let block = [0_i32; 4];
            let base = block.as_ptr().cast::<std::ffi::c_void>();
            // SAFETY: only the address is recorded and checked; nothing is read.
            unsafe {
                crate::ffi::map2check_map_malloc(base, 16);
                crate::ffi::map2check_check_load(
                    block.as_ptr().wrapping_add(4).cast(),
                    17,
                    0,
                    4,
                    b"main\0".as_ptr().cast(),
                );
            }
            println!("after-deref={:?}", current_property());
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn verifier_error_is_a_no_op_with_a_mode_and_the_deref_is_reported() {
        let out = run_surviving_child("verifier_error_with_memtrack_mode_child");
        assert!(out.contains("after-error=None"), "{out}");
        assert!(out.contains("after-deref=MemsafetyDeref"), "{out}");
    }

    #[test]
    fn verifier_error_with_target_mode_child() {
        if is_child() {
            println!("{STARTED}");
            crate::ffi::map2check_set_mode(5); // target
            crate::ffi::map2check_init();
            __VERIFIER_error();
            __VERIFIER_assert(0);
            println!("after-error={:?}", current_property());
            // SAFETY: NUL-terminated literal.
            unsafe { crate::ffi::map2check_reach_target(b"reach_error\0".as_ptr().cast(), 0, 12) };
            println!("after-target={:?}", current_property());
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn target_mode_reaches_only_through_map2check_reach_target() {
        let out = run_surviving_child("verifier_error_with_target_mode_child");
        assert!(out.contains("after-error=None"), "{out}");
        assert!(out.contains("after-target=Reachability"), "{out}");
    }
}
