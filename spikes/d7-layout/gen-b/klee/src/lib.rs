// SPDX-License-Identifier: GPL-3.0-only
//! D7 spike, strategy B: NonDetGeneratorKlee as a no_std crate.
#![no_std]
use core::ffi::{c_char, c_int, c_uint};

#[path = "../../common.rs"]
#[macro_use]
mod common;

extern "C" {
    fn __map2check_main__(argc: c_int, argv: *mut *mut c_char) -> c_int;
    fn klee_make_symbolic(addr: *mut u8, nbytes: usize, name: *const u8);
    fn klee_get_value_i64(v: i64) -> i64;
    fn klee_assume(cond: usize);
    fn _exit(code: c_int) -> !;
    fn malloc(n: usize) -> *mut u8;
    fn free(p: *mut u8);
    fn memcpy(d: *mut u8, s: *const u8, n: usize) -> *mut u8;
    // the core (Map2CheckFunctions.bc)
    fn nondet_log_init();
    fn nondet_log_destroy();
    fn map2check_nondet_memory_byte(line: c_uint, scope: c_uint, v: c_int, f: *const u8);
    fn __m2c_rt_nondet_log_len() -> c_uint;
    fn __m2c_rt_nondet_log_value(i: c_uint) -> *mut i64;
    fn __m2c_rt_nondet_log_to_file();
}

unsafe fn symbolic(p: *mut u8, n: usize, name: *const u8) {
    klee_make_symbolic(p, n, name);
}
nondet_types!(symbolic);

#[no_mangle]
pub unsafe extern "C" fn main(argc: c_int, argv: *mut *mut c_char) -> c_int {
    __map2check_main__(argc, argv)
}

#[no_mangle]
pub unsafe extern "C" fn map2check_non_det_memory(dest: *mut u8, size: usize) {
    if size == 0 {
        return;
    }
    let b = malloc(size);
    if b.is_null() {
        return;
    }
    klee_make_symbolic(b, size, b"non_det_memory\0".as_ptr());
    memcpy(dest, b, size);
    for i in 0..size {
        map2check_nondet_memory_byte(0, 0, *b.add(i) as c_int, b"__VERIFIER_nondet_memory\0".as_ptr());
    }
    free(b);
}

#[no_mangle]
pub unsafe extern "C" fn nondet_assume(expr: c_int) {
    if expr == 0 {
        let mut pruned = 0u8;
        klee_make_symbolic(&mut pruned, 1, b"map2check_pruned\0".as_ptr());
        _exit(0);
    }
}

#[no_mangle]
pub unsafe extern "C" fn nondet_init() {
    nondet_log_init();
}

#[no_mangle]
pub unsafe extern "C" fn nondet_destroy() {
    nondet_log_destroy();
}

#[no_mangle]
pub unsafe extern "C" fn nondet_generate_aux_witness_files() {
    let n = __m2c_rt_nondet_log_len();
    if n > 1024 {
        return;
    }
    for i in 0..n {
        let p = __m2c_rt_nondet_log_value(i);
        let v = *p;
        let k = klee_get_value_i64(v);
        klee_assume((v == k) as usize);
        *p = k;
    }
    __m2c_rt_nondet_log_to_file();
}
