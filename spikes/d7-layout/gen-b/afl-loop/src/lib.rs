// SPDX-License-Identifier: GPL-3.0-only
//! D7 spike, strategy B, AFL++ variant without longjmp: the persistent loop
//! is Rust (no IR), and a failed assume ends the process (_exit(0)), which
//! makes afl-fuzz restart the target through the fork server.
#![no_std]
use core::ffi::{c_int, c_uint};

#[path = "../../common.rs"]
#[macro_use]
mod common;

extern "C" {
    fn __map2check_main__(argc: c_int, argv: *mut *mut u8) -> c_int;
    fn __afl_persistent_loop(max: c_uint) -> c_int;
    fn read(fd: c_int, buf: *mut u8, n: usize) -> isize;
    fn _exit(code: c_int) -> !;
    static __afl_connected: c_int;
    static mut __afl_fuzz_len: *mut c_uint;
    static __afl_fuzz_ptr: *const u8;
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

#[no_mangle]
pub static mut __afl_sharedmem_fuzzing: c_int = 1;
#[no_mangle]
pub static mut __afl_fuzz_alt: [u8; 1048576] = [0; 1048576];
#[used]
static AFL_PERSISTENT_SIG: [u8; 23] = *b"##SIG_AFL_PERSISTENT##\0";

#[no_mangle]
pub unsafe extern "C" fn nondet_assume(expr: c_int) {
    if expr == 0 {
        _exit(0);
    }
}

#[no_mangle]
pub unsafe extern "C" fn main(_argc: c_int, _argv: *mut *mut u8) -> c_int {
    let sig = core::ptr::read_volatile(&AFL_PERSISTENT_SIG[0]);
    let _ = sig;
    while __afl_persistent_loop(if __afl_connected != 0 { 10000 } else { 1 }) != 0 {
        let (buf, len) = if !__afl_fuzz_ptr.is_null() {
            (__afl_fuzz_ptr, *__afl_fuzz_len as usize)
        } else {
            let alt = core::ptr::addr_of_mut!(__afl_fuzz_alt) as *mut u8;
            let r = read(0, alt, 1048576);
            *__afl_fuzz_len = if r < 0 { 0 } else { r as c_uint };
            (alt as *const u8, if r < 0 { 0 } else { r as usize })
        };
        map2check_afl_data = buf;
        map2check_afl_size = len;
        map2check_afl_index = 0;
        __map2check_main__(0, core::ptr::null_mut());
    }
    0
}
