// SPDX-License-Identifier: GPL-3.0-only
//! D7 spike (Task 1.1): the Rust core that becomes `Map2CheckFunctions.bc`.
//!
//! It owns the state and the logic. The other 20 modules are thin LLVM IR
//! (`../ll`, `../scripts/gen_ll.py`) that define exactly the external symbols
//! the C module of the same name defines, forwarding to the `__m2c_rt_*`
//! entry points below. The core reaches the other modules only through the
//! symbols the C runtime itself crosses between modules (`analysis_*`,
//! `nondet_*`, `generate_*`), so the C module graph is kept as is.
//!
//! Prototype scope: what `scripts/it/smoke/link-smoke.c` reaches in the five
//! modes (core, bb tracking, nondet log, property file, assert, overflow
//! add/sub/mul, witness files); the memory-safety entry points are stubs
//! emitted by gen_ll.py.
#![allow(clippy::missing_safety_doc)]

use std::ffi::{c_char, c_int, c_uint, CStr};
use std::io::Write;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;

// Cross-module symbols, defined by the mode, generator and witness modules,
// exactly as Map2CheckFunctions.c sees them.
extern "C" {
    fn analysis_init();
    fn analysis_destroy();
    fn analysis_is_program_correct() -> c_char;
    fn analysis_generate_aux_witness_files();
    fn nondet_init();
    fn nondet_destroy();
    fn nondet_generate_aux_witness_files();
    fn generate_aux_files(trackbb_log: *mut u8, violation: c_char);
    fn generate_confirmation_file();
    fn abort() -> !;
}

#[derive(Clone, Copy)]
struct NondetCall {
    line: u32,
    scope: u32,
    value: i64,
    function: usize,
    step: u32,
    kind: u32,
}

struct State {
    step: u32,
    sv_comp: bool,
    got_error: bool,
    trackbb: Vec<(u32, usize)>,
    nondet: Vec<NondetCall>,
}

static STATE: Mutex<State> = Mutex::new(State {
    step: 0,
    sv_comp: false,
    got_error: false,
    trackbb: Vec::new(),
    nondet: Vec::new(),
});
static RELEASED: AtomicBool = AtomicBool::new(false);

fn state() -> std::sync::MutexGuard<'static, State> {
    STATE.lock().unwrap_or_else(|e| e.into_inner())
}

unsafe fn cstr(p: *const c_char) -> &'static str {
    if p.is_null() {
        ""
    } else {
        CStr::from_ptr(p).to_str().unwrap_or("")
    }
}

// ---------------------------------------------------------------- core ABI

#[no_mangle]
pub extern "C" fn map2check_init(is_sv_comp: c_int) {
    {
        let mut s = state();
        s.step = 0;
        s.trackbb = Vec::new();
        if is_sv_comp != 0 {
            s.sv_comp = true;
        }
    }
    unsafe {
        analysis_init();
        nondet_init();
    }
}

#[no_mangle]
pub extern "C" fn map2check_get_current_step() -> c_uint {
    state().step
}

#[no_mangle]
pub extern "C" fn map2check_next_current_step() {
    state().step += 1;
}

#[no_mangle]
pub unsafe extern "C" fn map2check_track_bb(line: c_uint, function_name: *const c_char) {
    let mut s = state();
    if !s.trackbb.iter().rev().any(|(l, _)| *l == line) {
        s.trackbb.push((line, function_name as usize));
    }
}

#[no_mangle]
pub extern "C" fn __VERIFIER_error() {}

#[no_mangle]
pub unsafe extern "C" fn map2check_target_function(func: *const c_char, _scope: c_int, line: c_int) {
    write_property(5, line, func);
    map2check_error();
}

#[no_mangle]
pub extern "C" fn map2check_success() {
    unsafe { write_property(0, 0, b"\0".as_ptr().cast()) };
    map2check_exit();
}

#[no_mangle]
pub extern "C" fn map2check_error() {
    state().got_error = true;
    map2check_exit();
}

#[no_mangle]
pub extern "C" fn map2check_destroy() {
    if RELEASED.swap(true, Ordering::SeqCst) {
        return;
    }
    state().trackbb = Vec::new();
    unsafe {
        analysis_destroy();
        nondet_destroy();
    }
}

#[no_mangle]
pub extern "C" fn map2check_exit() {
    let mut got_error = state().got_error;
    if !got_error {
        got_error = unsafe { analysis_is_program_correct() } == 0;
        state().got_error = got_error;
    }
    // The C passes &trackbb_log; the Rust witness module reads the state.
    unsafe { generate_aux_files(std::ptr::null_mut(), got_error as c_char) };
    map2check_destroy();
    if got_error {
        unsafe {
            generate_confirmation_file();
            abort();
        }
    }
}

// ------------------------------------------------------- PropertyGenerator

fn put_file(name: &str, text: &str) {
    if let Ok(mut f) = std::fs::File::create(name) {
        let _ = f.write_all(text.as_bytes());
    }
}

#[no_mangle]
pub unsafe extern "C" fn write_property(violated: c_int, line: c_int, func: *const c_char) {
    let f = cstr(func);
    let loc = |tag: &str| format!("{tag}\nLine: {line}\nFunction: {f}\n");
    let text = match violated {
        0 => "NONE\n".to_string(),
        1 => "UNKNOWN\n".to_string(),
        2 => loc("FALSE-FREE"),
        3 => loc("FALSE-DEREF"),
        4 => "FALSE-MEMTRACK\n".to_string(),
        5 => loc("TARGET-REACHED"),
        6 => {
            put_file("map2check_property_overflow", &loc("OVERFLOW"));
            loc("OVERFLOW")
        }
        7 => {
            put_file("map2check_property_assert", &loc("ASSERT"));
            loc("ASSERT")
        }
        8 => "FALSE-MEMCLEANUP\n".to_string(),
        _ => loc("FALSE-DIVBYZERO"),
    };
    put_file("map2check_property", &text);
}

// --------------------------------------------------------------- NonDetLog

const T_INTEGER: u32 = 0;
const T_UNSIGNED: u32 = 1;
const T_DOUBLE: u32 = 4;
const T_FLOAT: u32 = 5;
const T_LONGLONG: u32 = 18;
const T_ULONGLONG: u32 = 19;
const T_MEMORY_BYTE: u32 = 23;

fn log_nondet(kind: u32, line: c_uint, scope: c_uint, value: i64, func: *const c_char) {
    let mut s = state();
    let step = s.step;
    s.nondet.push(NondetCall {
        line,
        scope,
        value,
        function: func as usize,
        step,
        kind,
    });
    s.step += 1;
}

macro_rules! nondet_log_fns {
    ($($name:ident: $ty:ty => $kind:expr;)*) => {$(
        #[no_mangle]
        pub extern "C" fn $name(line: c_uint, scope: c_uint, value: $ty, func: *const c_char) {
            log_nondet($kind, line, scope, value as i64, func);
        }
    )*};
}

// Type codes: only the ones the writer distinguishes matter in the spike.
nondet_log_fns! {
    map2check_nondet_int: c_int => T_INTEGER;
    map2check_nondet_char: c_int => 2;
    map2check_nondet_pointer: c_int => 3;
    map2check_nondet_ushort: c_int => 6;
    map2check_nondet_short: c_int => 7;
    map2check_nondet_long: c_int => 8;
    map2check_nondet_ulong: c_int => 9;
    map2check_nondet_bool: c_int => 10;
    map2check_nondet_uchar: c_int => 11;
    map2check_nondet_pchar: c_int => 12;
    map2check_nondet_size_t: c_int => 13;
    map2check_nondet_loff_t: c_int => 14;
    map2check_nondet_sector_t: c_int => 15;
    map2check_nondet_uint: c_int => 16;
    map2check_nondet_u8: c_int => 20;
    map2check_nondet_u16: c_int => 21;
    map2check_nondet_u32: c_int => 22;
    map2check_nondet_memory_byte: c_int => T_MEMORY_BYTE;
    map2check_nondet_unsigned: c_uint => T_UNSIGNED;
    map2check_nondet_longlong: i64 => T_LONGLONG;
    map2check_nondet_ulonglong: u64 => T_ULONGLONG;
}

#[no_mangle]
pub extern "C" fn map2check_nondet_double(line: c_uint, scope: c_uint, value: f64, func: *const c_char) {
    log_nondet(T_DOUBLE, line, scope, value.to_bits() as i64, func);
}

#[no_mangle]
pub extern "C" fn map2check_nondet_float(line: c_uint, scope: c_uint, value: f64, func: *const c_char) {
    log_nondet(T_FLOAT, line, scope, value.to_bits() as i64, func);
}

#[no_mangle]
pub extern "C" fn nondet_log_init() {
    state().nondet = Vec::new();
}

#[no_mangle]
pub extern "C" fn nondet_log_destroy() {
    state().nondet = Vec::new();
}

/// Rows of the nondet log, for the KLEE generator's concretization loop.
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_len() -> c_uint {
    state().nondet.len() as c_uint
}

/// Address of row `i`'s 64-bit value. Valid until the log changes; the KLEE
/// generator only uses it at exit, after the program stopped logging.
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_value(i: c_uint) -> *mut i64 {
    let mut s = state();
    match s.nondet.get_mut(i as usize) {
        Some(row) => &mut row.value,
        None => std::ptr::null_mut(),
    }
}

/// `nondet_log_to_file(map2check_nondet_get_log())` of the C generators.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_nondet_log_to_file() {
    let rows: Vec<NondetCall> = state().nondet.clone();
    let mut out = String::new();
    for (i, r) in rows.iter().enumerate() {
        let func = cstr(r.function as *const c_char);
        let value = match r.kind {
            T_UNSIGNED => (r.value as u32).to_string(),
            T_DOUBLE => format!("{:.6}", f64::from_bits(r.value as u64)),
            T_FLOAT => format!("{}", f64::from_bits(r.value as u64) as f32),
            T_LONGLONG => r.value.to_string(),
            T_ULONGLONG => (r.value as u64).to_string(),
            _ => (r.value as i32).to_string(),
        };
        out.push_str(&format!(
            "{i};{};{};{func};{};{value};{}\n",
            r.line, r.scope, r.step, r.kind
        ));
    }
    put_file("klee_log.csv", &out);
}

// ----------------------------------------------------- AnalysisModeAssert

#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_assert_map2check_assert(cond: c_int, line: c_int, func: *const c_char) {
    if cond == 0 {
        write_property(7, line, func);
        map2check_error();
    }
}

// --------------------------------------------------- AnalysisModeOverflow

fn fits_signed(v: i128, width: c_uint) -> bool {
    let w = width.clamp(1, 64);
    let min = -(1i128 << (w - 1));
    let max = (1i128 << (w - 1)) - 1;
    v >= min && v <= max
}

fn fits_unsigned(v: i128, width: c_uint) -> bool {
    let w = width.clamp(1, 64);
    v >= 0 && v < (1i128 << w)
}

unsafe fn overflow_at(line: c_uint, func: *const c_char) {
    write_property(6, line as c_int, func);
    map2check_error();
}

macro_rules! binop {
    ($name:ident, $t:ty, $op:tt, $fits:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $name(a: $t, b: $t, width: c_uint, line: c_uint, _scope: c_uint, func: *const c_char) {
            if !$fits((a as i128) $op (b as i128), width) {
                overflow_at(line, func);
            }
        }
    };
}

binop!(__m2c_rt_overflow_map2check_binop_add, i64, +, fits_signed);
binop!(__m2c_rt_overflow_map2check_binop_sub, i64, -, fits_signed);
binop!(__m2c_rt_overflow_map2check_binop_mul, i64, *, fits_signed);
binop!(__m2c_rt_overflow_map2check_binop_add_uint, u64, +, fits_unsigned);
binop!(__m2c_rt_overflow_map2check_binop_sub_uint, u64, -, fits_unsigned);
binop!(__m2c_rt_overflow_map2check_binop_mul_uint, u64, *, fits_unsigned);

#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_sdiv(
    a: i64,
    b: i64,
    width: c_uint,
    line: c_uint,
    _scope: c_uint,
    func: *const c_char,
) {
    if b == 0 {
        write_property(9, line as c_int, func);
        map2check_error();
    } else if !fits_signed((a as i128) / (b as i128), width) {
        overflow_at(line, func);
    }
}

#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_srem(
    a: i64,
    b: i64,
    width: c_uint,
    line: c_uint,
    scope: c_uint,
    func: *const c_char,
) {
    __m2c_rt_overflow_map2check_binop_sdiv(a, b, width, line, scope, func);
}

#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_overflowError(line: c_uint, func: *const c_char) {
    overflow_at(line, func);
}

// ------------------------------------------------------- WitnessGeneration

#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_witness_generate_aux_files(_log: *mut u8, violation: c_char) {
    let rows: Vec<(u32, usize)> = state().trackbb.clone();
    let mut out = String::new();
    for (line, func) in rows {
        out.push_str(&format!("{line};{}\n", cstr(func as *const c_char)));
    }
    put_file("track_bb_log.st", &out);
    analysis_generate_aux_witness_files();
    if violation != 0 || std::env::var_os("MAP2CHECK_SEED_REPLAY").is_some() {
        nondet_generate_aux_witness_files();
    }
}

#[no_mangle]
pub extern "C" fn __m2c_rt_witness_generate_confirmation_file() {
    put_file("map2check_checked_error", "END OF TIME\n");
}

// ------------------------------------------- strategy A as in the plan

#[cfg(feature = "a_literal")]
mod a_literal {
    //! The generator lives in the core. The generator .ll only defines
    //! `main` and a strong `__m2c_sel_generator` over the core's weak 0; the
    //! post-processing turns the core's `klee_make_symbolic` and
    //! `__m2c_afl_reject` declarations into extern_weak and the selector
    //! definition into a weak one.
    use super::*;
    use std::sync::atomic::AtomicU32;

    extern "C" {
        fn klee_make_symbolic(addr: *mut u8, nbytes: usize, name: *const c_char);
        fn __m2c_afl_reject() -> !;
        fn _exit(code: c_int) -> !;
    }

    /// 0 none, 1 klee, 2 afl. Mutable so LLVM cannot fold it before the
    /// linkage becomes weak.
    #[no_mangle]
    pub static __m2c_sel_generator: AtomicU32 = AtomicU32::new(0);

    #[no_mangle]
    pub static mut map2check_afl_data: *const u8 = std::ptr::null();
    #[no_mangle]
    pub static mut map2check_afl_size: usize = 0;
    #[no_mangle]
    pub static mut map2check_afl_index: usize = 0;

    unsafe fn afl_bytes(out: *mut u8, n: usize) {
        for i in 0..n {
            let b = if map2check_afl_index < map2check_afl_size {
                let v = *map2check_afl_data.add(map2check_afl_index);
                map2check_afl_index += 1;
                v
            } else {
                0
            };
            *out.add(i) = b;
        }
    }

    #[no_mangle]
    pub unsafe extern "C" fn map2check_non_det_int() -> c_int {
        let mut v: c_int = 0;
        match __m2c_sel_generator.load(Ordering::Relaxed) {
            1 => klee_make_symbolic((&mut v as *mut c_int).cast(), 4, b"non_det_int\0".as_ptr().cast()),
            2 => afl_bytes((&mut v as *mut c_int).cast(), 4),
            _ => {}
        }
        v
    }

    #[no_mangle]
    pub unsafe extern "C" fn nondet_assume(expr: c_int) {
        if expr != 0 {
            return;
        }
        match __m2c_sel_generator.load(Ordering::Relaxed) {
            1 => {
                let mut pruned = 0u8;
                klee_make_symbolic(&mut pruned, 1, b"map2check_pruned\0".as_ptr().cast());
                _exit(0)
            }
            // longjmp out of this Rust frame: the defect of this strategy.
            2 => __m2c_afl_reject(),
            _ => {}
        }
    }

    #[no_mangle]
    pub extern "C" fn nondet_init() {
        if __m2c_sel_generator.load(Ordering::Relaxed) != 0 {
            nondet_log_init();
        }
    }

    #[no_mangle]
    pub extern "C" fn nondet_destroy() {
        if __m2c_sel_generator.load(Ordering::Relaxed) != 0 {
            nondet_log_destroy();
        }
    }

    #[no_mangle]
    pub unsafe extern "C" fn nondet_generate_aux_witness_files() {
        if __m2c_sel_generator.load(Ordering::Relaxed) != 0 {
            __m2c_rt_nondet_log_to_file();
        }
    }
}
