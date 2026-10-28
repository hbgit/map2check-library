// SPDX-License-Identifier: GPL-3.0-only
//! D7 spike, strategy B: NonDetGeneratorNone as a no_std crate.
#![no_std]
use core::ffi::c_int;

#[path = "../../common.rs"]
#[macro_use]
mod common;

extern "C" {
    fn __map2check_main__() -> c_int;
    fn memset(p: *mut u8, c: c_int, n: usize) -> *mut u8;
}

#[no_mangle]
pub unsafe extern "C" fn main() -> c_int {
    __map2check_main__();
    0
}

macro_rules! zero {
    ($($name:ident: $t:ty;)*) => {$(
        #[no_mangle]
        pub extern "C" fn $name() -> $t { 0 as $t }
    )*};
}
zero! {
    map2check_non_det_int: i32; map2check_non_det_uint: u32; map2check_non_det_char: i8;
    map2check_non_det_ushort: u16; map2check_non_det_short: i16; map2check_non_det_double: f64;
    map2check_non_det_pointer: usize; map2check_non_det_long: i64; map2check_non_det_float: f32;
    map2check_non_det_longlong: i64; map2check_non_det_ulonglong: u64; map2check_non_det_u8: u8;
    map2check_non_det_u16: u16; map2check_non_det_u32: u32;
}

#[no_mangle]
pub unsafe extern "C" fn map2check_non_det_memory(dest: *mut u8, size: usize) {
    memset(dest, 0, size);
}
#[no_mangle]
pub extern "C" fn nondet_assume(_expr: c_int) {}
#[no_mangle]
pub extern "C" fn nondet_init() {}
#[no_mangle]
pub extern "C" fn nondet_destroy() {}
#[no_mangle]
pub extern "C" fn nondet_generate_aux_witness_files() {}
