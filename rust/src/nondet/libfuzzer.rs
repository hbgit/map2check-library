// SPDX-License-Identifier: GPL-3.0-only
//
// LibFuzzer nondeterministic value generation.
// Replaces nondet_gen_libfuzzer.c — eliminates all union type-punning
// by using f32::from_bits() / f64::from_bits() from safe Rust.

use std::sync::atomic::{AtomicUsize, Ordering};

static FUZZER_CURSOR: AtomicUsize = AtomicUsize::new(0);
static FUZZER_SIZE: AtomicUsize = AtomicUsize::new(0);

// Safety: written once from LLVMFuzzerTestOneInput before any reads.
static mut FUZZER_DATA: *const u8 = std::ptr::null();

/// Called by LibFuzzer before the test target runs.
///
/// # Safety
/// `data` must remain valid for the duration of one fuzzer iteration.
/// This is guaranteed by the LibFuzzer runtime contract.
#[no_mangle]
pub unsafe extern "C" fn LLVMFuzzerTestOneInput(data: *const u8, size: usize) -> i32 {
    // SAFETY: LibFuzzer guarantees `data` is valid for `size` bytes.
    FUZZER_DATA = data;
    FUZZER_SIZE.store(size, Ordering::SeqCst);
    FUZZER_CURSOR.store(0, Ordering::SeqCst);

    extern "C" {
        fn __map2check_main__() -> i32;
    }
    // SAFETY: user-defined entry point, linked by Map2Check instrumentation.
    __map2check_main__()
}

fn read_bytes(n: usize) -> Option<&'static [u8]> {
    let cursor = FUZZER_CURSOR.load(Ordering::SeqCst);
    let size = FUZZER_SIZE.load(Ordering::SeqCst);
    if cursor + n > size {
        return None;
    }
    // SAFETY: FUZZER_DATA was set from a valid LibFuzzer buffer; cursor+n <= size.
    let slice = unsafe { std::slice::from_raw_parts(FUZZER_DATA.add(cursor), n) };
    FUZZER_CURSOR.store(cursor + n, Ordering::SeqCst);
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
    //read_u8() % 2 == 0 lv=
    read_u8().is_multiple_of(2)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_char() -> i8 {
    read_u8() as i8
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uchar() -> u8 {
    read_u8()
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_short() -> i16 {
    read_bytes(2)
        .map(|b| i16::from_le_bytes(b.try_into().unwrap_or([0; 2])))
        .unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ushort() -> u16 {
    read_bytes(2)
        .map(|b| u16::from_le_bytes(b.try_into().unwrap_or([0; 2])))
        .unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_int() -> i32 {
    read_u32() as i32
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_uint() -> u32 {
    read_u32()
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_long() -> i64 {
    read_u64() as i64
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_ulong() -> u64 {
    read_u64()
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_float() -> f32 {
    // Uses f32::from_bits — replaces C union FloatPattern type-punning safely
    f32::from_bits(read_u32())
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_double() -> f64 {
    // Uses f64::from_bits — replaces C union DoublePattern type-punning safely
    f64::from_bits(read_u64())
}

#[no_mangle]
pub extern "C" fn __VERIFIER_nondet_size_t() -> usize {
    read_u64() as usize
}

//lv
// Cria uma função "falsa" apenas para os testes passarem no Linker
#[cfg(test)]
#[no_mangle]
pub extern "C" fn __map2check_main__() -> i32 {
    0 // Retorna 0 (sucesso) e não faz nada
}
