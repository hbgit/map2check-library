// SPDX-License-Identifier: GPL-3.0-only
//
// KLEE nondeterministic value generator: the `symex` runtime of Map2Check
// (feature `klee`, D1 route A', docs/cutover/decisoes.md).
//
// Built only from klee/Cargo.toml, with rustc 1.72.1 (LLVM 16), as bitcode
// that llvm-link-16 joins to the analysed program
// (scripts/build-klee-runtime.sh). Everything this file and the rest of the
// crate use must therefore compile on rustc 1.72 (D1 condition 5): no
// `unsafe extern`, no `LazyLock`, no std API newer than 1.72.
//
// Semantics are those of Map2Check develop's C generator
// (`modules/backend/library/lib/NonDetGeneratorKlee.c`):
//
// - each `__VERIFIER_nondet_<t>` makes a fresh object of `sizeof(type)`
//   bytes symbolic with `klee_make_symbolic`, named `non_det_<t>` as
//   develop names it (`"non_det_" #type`). The frontend reads the type back
//   from that name (`ktest_reader.cpp`, `decodeKtestObject`), and turns a
//   `.ktest` into a fuzzer seed by concatenating the objects' bytes
//   (`ktestToFuzzerBytes`): `sizeof(type)` bytes per value, in order, in
//   memory order (little-endian on x86-64), which is exactly what the
//   AFL++/libFuzzer reader of `libfuzzer.rs` consumes (D1 condition 9);
// - `__VERIFIER_assume` is `klee_assume`;
// - `main` calls the analysed program's renamed `main`
//   (`NonDetGeneratorKlee.c:16`);
// - values that reach the output (the witness logs, the JSON report) are
//   concretised first with `klee_get_value_*` ([`concretize`], D1
//   condition 7): formatting a symbolic value forks KLEE on every digit.
//
// Violations end the state through the core's `std::process::abort()`
// (`output/termination.rs`), which KLEE reports as an abort error, as it
// does for develop's `abort()` in `map2check_exit`.
#![allow(unsafe_code)]

use std::ffi::{c_char, c_int, c_void};

use super::NonDetValue;
use crate::state::AnalysisState;

extern "C" {
    fn klee_make_symbolic(addr: *mut c_void, nbytes: usize, name: *const c_char);
    fn klee_assume(condition: usize);
    fn klee_get_value_i32(expr: i32) -> i32;
    fn klee_get_value_i64(expr: i64) -> i64;
    /// The analysed program's `main`, renamed by the Map2CheckLibrary pass.
    fn __map2check_main__(argc: c_int, argv: *mut *mut c_char) -> c_int;
}

/// A fresh symbolic value of `T`'s size. `name` is NUL-terminated.
///
/// `T` is one of the integer types below: any bit pattern is a valid `T`,
/// so KLEE may give the object any value.
fn symbolic<T: Copy + Default>(name: &'static [u8]) -> T {
    debug_assert_eq!(name.last(), Some(&0));
    let mut value = T::default();
    // SAFETY: `value` is a live local of `size_of::<T>()` bytes, and `name`
    // is a NUL-terminated static string.
    unsafe {
        klee_make_symbolic(
            (&mut value as *mut T).cast::<c_void>(),
            std::mem::size_of::<T>(),
            name.as_ptr().cast::<c_char>(),
        );
    }
    value
}

// ── Public nondet generators ─────────────────────────────────────────────────

macro_rules! klee_nondet {
    ($(#[$doc:meta])* $fn_name:ident, $ty:ty, $name:literal) => {
        $(#[$doc])*
        #[no_mangle]
        pub extern "C" fn $fn_name() -> $ty {
            crate::ffi::ffi_guard(|| symbolic::<$ty>(concat!($name, "\0").as_bytes()), 0)
        }
    };
}

klee_nondet!(__VERIFIER_nondet_char, i8, "non_det_char");
klee_nondet!(__VERIFIER_nondet_uchar, u8, "non_det_uchar");
klee_nondet!(__VERIFIER_nondet_short, i16, "non_det_short");
klee_nondet!(__VERIFIER_nondet_ushort, u16, "non_det_ushort");
klee_nondet!(__VERIFIER_nondet_int, i32, "non_det_int");
klee_nondet!(
    /// develop has `map2check_non_det_uint` and `_unsigned`; both are
    /// `__VERIFIER_nondet_uint` in the core (symbol-matrix.tsv) and the
    /// frontend reads both names as a 4-byte unsigned.
    __VERIFIER_nondet_uint,
    u32,
    "non_det_uint"
);
klee_nondet!(__VERIFIER_nondet_long, i64, "non_det_long");
klee_nondet!(__VERIFIER_nondet_ulong, u64, "non_det_ulong");
klee_nondet!(__VERIFIER_nondet_size_t, usize, "non_det_size_t");
klee_nondet!(
    /// glibc's `loff_t` is `long long`.
    __VERIFIER_nondet_loff_t,
    i64,
    "non_det_loff_t"
);
klee_nondet!(
    /// develop: `#define sector_t unsigned long` (`NonDetGenerator.h:112`).
    __VERIFIER_nondet_sector_t,
    std::os::raw::c_ulong,
    "non_det_sector_t"
);

/// develop's `bool` is `typedef int bool` (`NonDetGenerator.h:74`): a 4-byte
/// object, returned as that `int` converted to `_Bool`, as `libfuzzer.rs`
/// reads it.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_bool() -> bool {
    crate::ffi::ffi_guard(|| symbolic::<i32>(b"non_det_bool\0") != 0, false)
}

/// Four bytes, like `int`; develop has no `float` generator. The frontend
/// does not know the name `non_det_float` and decodes it as a signed int.
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_float() -> f32 {
    crate::ffi::ffi_guard(|| f32::from_bits(symbolic::<u32>(b"non_det_float\0")), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_double() -> f64 {
    crate::ffi::ffi_guard(|| f64::from_bits(symbolic::<u64>(b"non_det_double\0")), 0.0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_pointer() -> *mut c_void {
    // An integer turned into a pointer; nothing here dereferences it.
    crate::ffi::ffi_guard(
        || symbolic::<usize>(b"non_det_pointer\0") as *mut c_void,
        std::ptr::null_mut(),
    )
}

/// `MAP2CHECK_MAX_FUZZED_STRING` of the AFL++ reader (`libfuzzer.rs`).
const MAX_FUZZED_STRING: u32 = 4096;

/// A NUL-terminated string allocated with the C `malloc`, as develop's
/// `map2check_non_det_pchar` (`NonDetGeneratorKlee.c:40-55`): a symbolic
/// `unsigned` length (object `non_det_unsigned`), NULL when it is 0 or
/// when `malloc` fails, then `length - 1` symbolic chars (`non_det_char`
/// each) and a NUL.
///
/// Unlike develop's KLEE generator, the length is capped at 4096 as the
/// AFL++ reader caps it, so that a KLEE vector replays through the fuzzer
/// reader as the same string (D1 condition 9).
#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_pchar() -> *mut c_char {
    extern "C" {
        fn malloc(size: usize) -> *mut c_void;
    }
    crate::ffi::ffi_guard(
        || {
            let length = symbolic::<u32>(b"non_det_unsigned\0").min(MAX_FUZZED_STRING) as usize;
            if length == 0 {
                return std::ptr::null_mut();
            }
            // SAFETY: plain C allocation; the result is checked for NULL.
            let string = unsafe { malloc(length) }.cast::<u8>();
            if string.is_null() {
                return std::ptr::null_mut();
            }
            for i in 0..length - 1 {
                // SAFETY: `i < length`, inside the `length`-byte block.
                unsafe { string.add(i).write(symbolic::<u8>(b"non_det_char\0")) };
            }
            // SAFETY: `length - 1 < length`.
            unsafe { string.add(length - 1).write(0) };
            string.cast()
        },
        std::ptr::null_mut(),
    )
}

// ── SV-COMP verifier primitives ──────────────────────────────────────────────

/// `nondet_assume` of develop's KLEE generator: `klee_assume(expr)`. A
/// false condition ends the path (KLEE stops exploring it); one that is
/// provably false is a KLEE user error, as in develop.
#[no_mangle]
pub extern "C" fn __VERIFIER_assume(condition: i32) {
    crate::ffi::ffi_guard(
        || {
            // SAFETY: KLEE intrinsic, takes the condition by value.
            unsafe { klee_assume(usize::from(condition != 0)) }
        },
        (),
    );
}

/// SV-COMP reachability primitive, as in `libfuzzer.rs`: with an analysis
/// mode set it does nothing, as develop's (`Map2CheckFunctions.c:57-59`),
/// so KLEE keeps exploring; with none it records `Reachability` and aborts
/// (SD-08).
#[no_mangle]
pub extern "C" fn __VERIFIER_error() {
    if crate::ffi::ffi_guard(super::record_verifier_error, false) {
        std::process::abort();
    }
}

/// SV-COMP assert primitive: `__VERIFIER_error()` when `condition` is false
/// (a no-op with a mode set, as develop's `AnalysisModeAssert.c:25-27`).
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

/// KLEE's entry point. develop's KLEE generator defines `main` the same way
/// (`NonDetGeneratorKlee.c:16`): the passes renamed the program's `main` to
/// `__map2check_main__` and inserted the mode, init and success calls.
#[no_mangle]
pub extern "C" fn main(argc: c_int, argv: *mut *mut c_char) -> c_int {
    crate::ffi::ffi_guard(
        // SAFETY: the analysed program's entry point, linked by llvm-link.
        || unsafe { __map2check_main__(argc, argv) },
        0,
    )
}

// ── Concretisation before output (D1 condition 7) ────────────────────────────

/// A concrete value of `expr` in the current path, which the path is then
/// constrained to. Constraining it keeps the values concretised one after
/// another jointly consistent (as KLEE does when it concretises the
/// arguments of an external call such as develop's `fprintf`).
fn concrete_i64(expr: i64) -> i64 {
    // SAFETY: KLEE intrinsics, by value.
    unsafe {
        let value = klee_get_value_i64(expr);
        klee_assume(usize::from(expr == value));
        value
    }
}

fn concrete_i32(expr: i32) -> i32 {
    // SAFETY: KLEE intrinsics, by value.
    unsafe {
        let value = klee_get_value_i32(expr);
        klee_assume(usize::from(expr == value));
        value
    }
}

fn concrete_usize(expr: usize) -> usize {
    concrete_i64(expr as i64) as usize
}

fn concrete_value(value: &NonDetValue) -> NonDetValue {
    use NonDetValue as V;
    match *value {
        V::Int(v) => V::Int(concrete_i32(v)),
        V::UInt(v) => V::UInt(concrete_i32(v as i32) as u32),
        V::Long(v) => V::Long(concrete_i64(v)),
        V::Char(v) => V::Char(concrete_i32(i32::from(v)) as i8),
        V::Float(v) => V::Float(f32::from_bits(concrete_i32(v.to_bits() as i32) as u32)),
        V::Double(v) => V::Double(f64::from_bits(concrete_i64(v.to_bits() as i64) as u64)),
        V::Unsigned(v) => V::Unsigned(concrete_i32(v as i32) as u32),
        V::Pointer(v) => V::Pointer(concrete_usize(v)),
        V::UShort(v) => V::UShort(concrete_i32(i32::from(v)) as u16),
        V::Short(v) => V::Short(concrete_i32(i32::from(v)) as i16),
        V::ULong(v) => V::ULong(concrete_i64(v as i64) as u64),
        V::Bool(v) => V::Bool(concrete_i32(v)),
        V::UChar(v) => V::UChar(concrete_i32(i32::from(v)) as u8),
        V::PChar(v) => V::PChar(concrete_usize(v)),
        V::SizeT(v) => V::SizeT(concrete_usize(v)),
        V::LoffT(v) => V::LoffT(concrete_i64(v)),
        V::SectorT(v) => V::SectorT(concrete_i64(v as i64) as u64),
    }
}

fn concretize_memtrack(entry: &mut crate::memtrack::MemTrackEntry) {
    entry.var_addr = concrete_usize(entry.var_addr);
    entry.points_to = concrete_usize(entry.points_to);
    entry.size_destiny = concrete_usize(entry.size_destiny);
    entry.size_primitive = concrete_usize(entry.size_primitive);
}

/// Replaces every value of the state that the output formats and that the
/// program can make symbolic (nondet values; addresses and sizes of the
/// memory records, which a symbolic size or index reaches) by a concrete
/// value of the current path. Called right before the witness logs or the
/// JSON report are written (`output::prepare_for_output`).
pub(crate) fn concretize(state: &mut AnalysisState) {
    for entry in &mut state.nondets {
        entry.value = concrete_value(&entry.value);
    }
    for entry in &mut state.memtrack {
        concretize_memtrack(entry);
    }
    if let Some(entry) = state.failed_free.as_mut() {
        concretize_memtrack(entry);
    }
}
