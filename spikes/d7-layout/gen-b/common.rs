// SPDX-License-Identifier: GPL-3.0-only
// D7 spike, strategy B: shared by the no_std generator crates (included
// with #[path]). `nondet_types!(reader)` defines map2check_non_det_<t> for the
// types NonDetGeneratorKlee.c/NonDetGeneratorAFL.c define, each filled by
// `reader(ptr, size, name)`.
#[macro_export]
macro_rules! nondet_types {
    ($reader:path) => {
        nondet_types!(@one $reader, map2check_non_det_char, i8, b"non_det_char\0");
        nondet_types!(@one $reader, map2check_non_det_pointer, usize, b"non_det_pointer\0");
        nondet_types!(@one $reader, map2check_non_det_ushort, u16, b"non_det_ushort\0");
        nondet_types!(@one $reader, map2check_non_det_short, i16, b"non_det_short\0");
        nondet_types!(@one $reader, map2check_non_det_long, i64, b"non_det_long\0");
        nondet_types!(@one $reader, map2check_non_det_ulong, u64, b"non_det_ulong\0");
        nondet_types!(@one $reader, map2check_non_det_bool, i32, b"non_det_bool\0");
        nondet_types!(@one $reader, map2check_non_det_uchar, u8, b"non_det_uchar\0");
        nondet_types!(@one $reader, map2check_non_det_size_t, u64, b"non_det_size_t\0");
        nondet_types!(@one $reader, map2check_non_det_loff_t, i64, b"non_det_loff_t\0");
        nondet_types!(@one $reader, map2check_non_det_sector_t, u64, b"non_det_sector_t\0");
        nondet_types!(@one $reader, map2check_non_det_double, f64, b"non_det_double\0");
        nondet_types!(@one $reader, map2check_non_det_int, i32, b"non_det_int\0");
        nondet_types!(@one $reader, map2check_non_det_uint, u32, b"non_det_uint\0");
        nondet_types!(@one $reader, map2check_non_det_unsigned, u32, b"non_det_unsigned\0");
        nondet_types!(@one $reader, map2check_non_det_float, f32, b"non_det_float\0");
        nondet_types!(@one $reader, map2check_non_det_longlong, i64, b"non_det_longlong\0");
        nondet_types!(@one $reader, map2check_non_det_ulonglong, u64, b"non_det_ulonglong\0");
        nondet_types!(@one $reader, map2check_non_det_u8, u8, b"non_det_u8\0");
        nondet_types!(@one $reader, map2check_non_det_u16, u16, b"non_det_u16\0");
        nondet_types!(@one $reader, map2check_non_det_u32, u32, b"non_det_u32\0");

        #[no_mangle]
        pub unsafe extern "C" fn map2check_non_det_pchar() -> *mut u8 {
            let mut len = map2check_non_det_unsigned();
            if len == 0 {
                return core::ptr::null_mut();
            }
            if len > 4096 {
                len = 4096;
            }
            let s = malloc(len as usize);
            if s.is_null() {
                return s;
            }
            let mut i = 0u32;
            while i < len - 1 {
                *s.add(i as usize) = map2check_non_det_char() as u8;
                i += 1;
            }
            *s.add(i as usize) = 0;
            s
        }
    };
    (@one $reader:path, $name:ident, $t:ty, $label:expr) => {
        #[no_mangle]
        pub unsafe extern "C" fn $name() -> $t {
            let mut v = core::mem::MaybeUninit::<$t>::zeroed();
            $reader(v.as_mut_ptr().cast(), core::mem::size_of::<$t>(), $label.as_ptr());
            v.assume_init()
        }
    };
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    extern "C" {
        fn abort() -> !;
    }
    unsafe { abort() }
}
