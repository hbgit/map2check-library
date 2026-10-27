// SPDX-License-Identifier: GPL-3.0-only
//
// The C conversions of the result files, written into a byte buffer: the
// `%u`/`%d`/`%lld`, `%p`, `%lf` and `%.9g` that the C runtime of Map2Check
// `develop` prints with `fprintf`/`snprintf` (`PropertyGenerator.c`,
// `TrackBBLog.c`, `ListLog.c`, `AllocationLog.c`, `HeapLog.c`,
// `NonDetLog.c`), as glibc prints them.
//
// Every build uses these, and they never go through `core::fmt`: the
// drop-in core (`Map2CheckFunctions.bc`) is compiled three times by
// `afl-clang-fast` on every Map2Check run, and `core::fmt` with its float
// formatting (Grisu and Dragon) made up most of its IR (Task 3.3).
//
// The floating-point conversions are exact: the value `m * 2^e` is written
// out in full as a decimal integer (`m * 5^k` with `k = -e` decimals, or
// `m * 2^e`), then rounded at the printed digit, a tie to even, as glibc
// does in the default rounding mode.
#![deny(unsafe_code)]

/// Appends `bytes`. Not inlined: the drop-in core appends at every field
/// of every row, and an inlined `Vec` growth check at each one was a large
/// part of its IR (Task 3.3).
#[inline(never)]
pub fn put(out: &mut Vec<u8>, bytes: &[u8]) {
    out.extend_from_slice(bytes);
}

/// Appends one byte ([`put`]).
#[inline(never)]
pub fn put_byte(out: &mut Vec<u8>, byte: u8) {
    out.push(byte);
}

/// `%u`, `%lu`, `%llu`.
pub fn put_u64(out: &mut Vec<u8>, mut value: u64) {
    let mut digits = [0u8; 20];
    let mut at = digits.len();
    loop {
        at -= 1;
        digits[at] = b'0' + (value % 10) as u8;
        value /= 10;
        if value == 0 {
            break;
        }
    }
    out.extend_from_slice(&digits[at..]);
}

/// `%d`, `%ld`, `%lld`.
pub fn put_i64(out: &mut Vec<u8>, value: i64) {
    if value < 0 {
        out.push(b'-');
    }
    put_u64(out, value.unsigned_abs());
}

/// `%p` of glibc: `(nil)` for NULL, otherwise `0x` and lowercase hex.
pub fn put_ptr(out: &mut Vec<u8>, address: u64) {
    if address == 0 {
        out.extend_from_slice(b"(nil)");
        return;
    }
    out.extend_from_slice(b"0x");
    put_hex(out, address);
}

/// `%lx`: lowercase hex, `0` for zero.
pub fn put_hex(out: &mut Vec<u8>, mut value: u64) {
    let mut digits = [0u8; 16];
    let mut at = digits.len();
    loop {
        at -= 1;
        digits[at] = b"0123456789abcdef"[(value & 0xf) as usize];
        value >>= 4;
        if value == 0 {
            break;
        }
    }
    out.extend_from_slice(&digits[at..]);
}

/// `inf`/`nan` with the sign glibc prints; true when `bits` is one of them.
fn put_special(out: &mut Vec<u8>, negative: bool, exponent_all_ones: bool, mantissa: u64) -> bool {
    if !exponent_all_ones {
        return false;
    }
    if negative {
        out.push(b'-');
    }
    out.extend_from_slice(if mantissa == 0 { b"inf" } else { b"nan" });
    true
}

/// The exact decimal digits of a finite, non-negative `m * 2^e`: the
/// digits of an integer and the number of them that are decimals. No
/// leading zeros; `"0"` with 0 decimals for zero.
fn exact_digits(mut m: u64, mut e: i32) -> (Vec<u8>, usize) {
    if m == 0 {
        return (vec![b'0'], 0);
    }
    while m & 1 == 0 {
        m >>= 1;
        e += 1;
    }
    // Little-endian base-10^9 limbs of m * 2^e (e >= 0) or m * 5^-e.
    let mut limbs: Vec<u32> = vec![(m % 1_000_000_000) as u32];
    let mut high = m / 1_000_000_000;
    while high != 0 {
        limbs.push((high % 1_000_000_000) as u32);
        high /= 1_000_000_000;
    }
    let (factor, mut count, decimals) = if e >= 0 {
        (2u64, e as u32, 0usize)
    } else {
        (5u64, e.unsigned_abs(), e.unsigned_abs() as usize)
    };
    while count > 0 {
        // Up to 2^29 or 5^12 at a time: the product fits in a u64.
        let (step, mul) = if factor == 2 {
            let s = count.min(29);
            (s, 1u64 << s)
        } else {
            let s = count.min(12);
            (s, 5u64.pow(s))
        };
        let mut carry = 0u64;
        for limb in limbs.iter_mut() {
            let v = u64::from(*limb) * mul + carry;
            *limb = (v % 1_000_000_000) as u32;
            carry = v / 1_000_000_000;
        }
        while carry != 0 {
            limbs.push((carry % 1_000_000_000) as u32);
            carry /= 1_000_000_000;
        }
        count -= step;
    }
    let mut digits = Vec::with_capacity(limbs.len() * 9);
    let top = limbs.len() - 1;
    put_u64(&mut digits, u64::from(limbs[top]));
    for &limb in limbs[..top].iter().rev() {
        let mut chunk = [b'0'; 9];
        let mut v = limb;
        for slot in chunk.iter_mut().rev() {
            *slot = b'0' + (v % 10) as u8;
            v /= 10;
        }
        digits.extend_from_slice(&chunk);
    }
    (digits, decimals)
}

/// Keeps the first `keep` digits of `digits`, rounded by the ones dropped:
/// up above one half, and a tie to even. Returns true when the rounding
/// carried out of the first digit (all nines): the kept digits are then
/// `1` followed by zeros, one more than `keep` long.
fn round_digits(digits: &mut Vec<u8>, keep: usize) -> bool {
    if keep >= digits.len() {
        return false;
    }
    let first = digits[keep];
    let rest_zero = digits[keep + 1..].iter().all(|&d| d == b'0');
    let odd = keep > 0 && (digits[keep - 1] - b'0') % 2 == 1;
    let up = first > b'5' || (first == b'5' && (!rest_zero || odd));
    digits.truncate(keep);
    if !up {
        return false;
    }
    for d in digits.iter_mut().rev() {
        if *d == b'9' {
            *d = b'0';
        } else {
            *d += 1;
            return false;
        }
    }
    digits.insert(0, b'1');
    true
}

/// The sign, the biased exponent field and the mantissa field of a double.
fn split_f64(value: f64) -> (bool, i32, u64) {
    let bits = value.to_bits();
    (
        bits >> 63 != 0,
        ((bits >> 52) & 0x7ff) as i32,
        bits & ((1u64 << 52) - 1),
    )
}

/// `m` and `e` of a finite double with this exponent field and mantissa.
fn mantissa_exponent(field: i32, mantissa: u64) -> (u64, i32) {
    if field == 0 {
        (mantissa, -1074)
    } else {
        (mantissa | (1u64 << 52), field - 1075)
    }
}

/// `%lf` of glibc: six decimals, `inf`/`nan` with their sign, `-` on a
/// negative zero.
pub fn put_lf(out: &mut Vec<u8>, value: f64) {
    let (negative, field, mantissa) = split_f64(value);
    if put_special(out, negative, field == 0x7ff, mantissa) {
        return;
    }
    let (m, e) = mantissa_exponent(field, mantissa);
    let (mut digits, decimals) = exact_digits(m, e);
    if decimals > 6 {
        let dropped = decimals - 6;
        match dropped.cmp(&digits.len()) {
            // Below a tenth of the sixth decimal: rounds to zero.
            std::cmp::Ordering::Greater => digits = vec![b'0'],
            // The first dropped digit is the seventh decimal.
            std::cmp::Ordering::Equal => {
                digits.insert(0, b'0');
                round_digits(&mut digits, 1);
            }
            std::cmp::Ordering::Less => {
                let keep = digits.len() - dropped;
                round_digits(&mut digits, keep);
            }
        }
    } else {
        digits.extend(std::iter::repeat(b'0').take(6 - decimals));
    }
    // `digits` now holds the value times 10^6.
    if digits.len() < 7 {
        let mut padded = vec![b'0'; 7 - digits.len()];
        padded.extend_from_slice(&digits);
        digits = padded;
    }
    if negative {
        out.push(b'-');
    }
    let point = digits.len() - 6;
    out.extend_from_slice(&digits[..point]);
    out.push(b'.');
    out.extend_from_slice(&digits[point..]);
}

/// `%.9g` of glibc on a `float` (`NonDetLog.c:99`): nine significant digits,
/// `%f` style for decimal exponents -4 to 8, `%e` style otherwise (at least
/// two exponent digits), trailing zeros and a trailing point removed.
pub fn put_g9(out: &mut Vec<u8>, value: f32) {
    const P: usize = 9;
    let (negative, field, mantissa) = split_f64(f64::from(value));
    if put_special(out, negative, field == 0x7ff, mantissa) {
        return;
    }
    if negative {
        out.push(b'-');
    }
    let (m, e) = mantissa_exponent(field, mantissa);
    if m == 0 {
        out.push(b'0');
        return;
    }
    let (mut digits, decimals) = exact_digits(m, e);
    // The decimal exponent of the leading digit, before and after rounding.
    let mut x = digits.len() as i32 - 1 - decimals as i32;
    if round_digits(&mut digits, P) {
        x += 1;
        digits.truncate(P);
    }
    digits.resize(P, b'0');
    while digits.len() > 1 && digits[digits.len() - 1] == b'0' {
        digits.pop();
    }
    if (-4..P as i32).contains(&x) {
        if x < 0 {
            out.extend_from_slice(b"0.");
            out.extend(std::iter::repeat(b'0').take((-x - 1) as usize));
            out.extend_from_slice(&digits);
        } else {
            let int_len = x as usize + 1;
            if digits.len() <= int_len {
                out.extend_from_slice(&digits);
                out.extend(std::iter::repeat(b'0').take(int_len - digits.len()));
            } else {
                out.extend_from_slice(&digits[..int_len]);
                out.push(b'.');
                out.extend_from_slice(&digits[int_len..]);
            }
        }
    } else {
        out.push(digits[0]);
        if digits.len() > 1 {
            out.push(b'.');
            out.extend_from_slice(&digits[1..]);
        }
        out.push(b'e');
        out.push(if x < 0 { b'-' } else { b'+' });
        if x.unsigned_abs() < 10 {
            out.push(b'0');
        }
        put_u64(out, u64::from(x.unsigned_abs()));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn s(f: impl FnOnce(&mut Vec<u8>)) -> String {
        let mut out = Vec::new();
        f(&mut out);
        String::from_utf8(out).unwrap()
    }

    #[allow(unsafe_code)]
    fn glibc(format: &[u8], value: f64) -> String {
        // A byte string, not a `c""` literal: rustc 1.72 (the drop-in build)
        // cannot lex those.
        assert_eq!(format.last(), Some(&0));
        extern "C" {
            fn snprintf(
                buf: *mut std::os::raw::c_char,
                n: usize,
                format: *const std::os::raw::c_char,
                ...
            ) -> std::os::raw::c_int;
        }
        let mut buf = vec![0u8; 2048];
        // SAFETY: a buffer of `buf.len()` bytes, a format with one double.
        let n = unsafe {
            snprintf(
                buf.as_mut_ptr().cast(),
                buf.len(),
                format.as_ptr().cast(),
                value,
            )
        };
        buf.truncate(n as usize);
        String::from_utf8(buf).unwrap()
    }

    fn values() -> Vec<f64> {
        let mut v = vec![
            0.0,
            -0.0,
            0.5,
            2.5,
            1.0e-7,
            5.0e-7,
            4.999_999_9e-7,
            1.5e-6,
            2.5e-6,
            0.000_000_5,
            0.000_001_5,
            123_456.789,
            1e300,
            -1e300,
            f64::MAX,
            f64::MIN_POSITIVE,
            5e-324,
            f64::INFINITY,
            f64::NEG_INFINITY,
            f64::NAN,
            -f64::NAN,
            1e-30,
            9.999_999_5,
            999_999_999.5,
            0.000_099_999_999_5,
            f64::from(f32::MAX),
            f64::from(f32::MIN_POSITIVE),
            f64::from(f32::from_bits(1)),
            std::f64::consts::PI,
            16_777_216.0,
            1e9,
            1e8,
            123_456_789.0,
            0.0001,
            0.000_012_345_678_9,
        ];
        // A deterministic spread of bit patterns (xorshift).
        let mut x = 0x2545_f491_4f6c_dd1du64;
        for _ in 0..4000 {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            v.push(f64::from_bits(x));
            v.push(f64::from(f32::from_bits(x as u32)));
            v.push((x % 2_000_000) as f64 / 1024.0 - 900.0);
        }
        v
    }

    #[test]
    fn integers_and_pointers_match_printf() {
        assert_eq!(s(|o| put_u64(o, 0)), "0");
        assert_eq!(s(|o| put_u64(o, u64::MAX)), "18446744073709551615");
        assert_eq!(s(|o| put_i64(o, i64::MIN)), "-9223372036854775808");
        assert_eq!(s(|o| put_i64(o, -1)), "-1");
        assert_eq!(s(|o| put_ptr(o, 0)), "(nil)");
        assert_eq!(s(|o| put_ptr(o, 0x1000_0100)), "0x10000100");
        assert_eq!(s(|o| put_ptr(o, u64::MAX)), "0xffffffffffffffff");
    }

    #[test]
    fn lf_matches_glibc() {
        for v in values() {
            assert_eq!(s(|o| put_lf(o, v)), glibc(b"%lf\0", v), "{v:e}");
        }
    }

    #[test]
    fn g9_of_a_float_matches_glibc() {
        for v in values() {
            let f = v as f32;
            assert_eq!(s(|o| put_g9(o, f)), glibc(b"%.9g\0", f64::from(f)), "{f:e}");
        }
    }
}
