// SPDX-License-Identifier: GPL-3.0-only
//! D7 spike, strategy B: NonDetGeneratorAFL as a no_std crate. main,
//! nondet_assume (setjmp/longjmp) and the AFL++ globals are IR
//! (b-afl-main.ll, written by scripts/gen_ll.py) linked into this module.
#![no_std]
use core::ffi::{c_int, c_uint};

#[path = "../../common.rs"]
#[macro_use]
mod common;

extern "C" {
    fn malloc(n: usize) -> *mut u8;
    fn nondet_log_init();
    fn nondet_log_destroy();
    fn map2check_nondet_memory_byte(line: c_uint, scope: c_uint, v: c_int, f: *const u8);
    fn __m2c_rt_nondet_log_to_file();
}

#[no_mangle]
pub static mut map2check_afl_data: *const u8 = core::ptr::null();
#[no_mangle]
pub static mut map2check_afl_size: usize = 0;
#[no_mangle]
pub static mut map2check_afl_index: usize = 0;

#[no_mangle]
pub unsafe extern "C" fn get_next_input_from_afl() -> u8 {
    if map2check_afl_index < map2check_afl_size {
        let b = *map2check_afl_data.add(map2check_afl_index);
        map2check_afl_index += 1;
        b
    } else {
        0
    }
}

unsafe fn bytes(p: *mut u8, n: usize, _name: *const u8) {
    for i in 0..n {
        *p.add(i) = get_next_input_from_afl();
    }
}
nondet_types!(bytes);

#[no_mangle]
pub unsafe extern "C" fn map2check_non_det_memory(dest: *mut u8, size: usize) {
    bytes(dest, size, core::ptr::null());
    for i in 0..size {
        map2check_nondet_memory_byte(0, 0, *dest.add(i) as c_int, b"__VERIFIER_nondet_memory\0".as_ptr());
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
    __m2c_rt_nondet_log_to_file();
}
