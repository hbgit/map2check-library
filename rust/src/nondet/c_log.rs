// SPDX-License-Identifier: GPL-3.0-only
//
// The nondet log of Map2Check's C runtime (`NonDetLog.c`): the rows that the
// `map2check_nondet_<t>` calls of the instrumented program append, and
// `nondet_log_to_file`, which writes them to `klee_log.csv`.
//
// This log is not the JSON-report log (`AnalysisState::nondets`, typed
// `NonDetValue`): its rows hold what the C `NONDET_CALL` holds, an
// `enum NONDET_TYPE` number and a union of 8 bytes, so that U8, U16, U32,
// MEMORY_BYTE, LONGLONG and ULONGLONG keep the numbers and the printing
// rules of the C file.
#![deny(unsafe_code)]

use std::path::Path;

/// `FUNCTION_MAX_LENGTH_NAME` (`Map2CheckTypes.h:20`).
pub const FUNCTION_MAX_LENGTH_NAME: usize = 35;

/// `klee_log_file` (`NonDetLog.c:13`).
pub const KLEE_LOG_FILE: &str = "klee_log.csv";

/// `enum NONDET_TYPE` (`Map2CheckTypes.h:41-58`).
pub mod kind {
    pub const INTEGER: i32 = 0;
    pub const CHAR: i32 = 1;
    pub const POINTER: i32 = 2;
    pub const USHORT: i32 = 3;
    pub const LONG: i32 = 4;
    pub const UNSIGNED: i32 = 5;
    pub const ULONG: i32 = 6;
    pub const BOOL: i32 = 7;
    pub const UCHAR: i32 = 8;
    pub const PCHAR: i32 = 9;
    pub const SIZE_T: i32 = 10;
    pub const LOFF_T: i32 = 11;
    pub const SECTOR_T: i32 = 12;
    pub const UINT: i32 = 13;
    pub const SHORT: i32 = 14;
    pub const DOUBLE: i32 = 15;
    pub const FLOAT: i32 = 16;
    pub const LONGLONG: i32 = 17;
    pub const ULONGLONG: i32 = 18;
    pub const U8: i32 = 19;
    pub const U16: i32 = 20;
    pub const U32: i32 = 21;
    pub const MEMORY_BYTE: i32 = 22;
}

/// One `NONDET_CALL` (`Map2CheckTypes.h:150-172`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CNondetCall {
    /// `enum NONDET_TYPE` number.
    pub kind: i32,
    pub line: u32,
    pub scope: u32,
    pub step: u32,
    /// The 8 bytes of the C `value` union, as a little-endian integer:
    /// `as_int`/`as_unsigned` are the low 32 bits.
    value: u64,
    /// `function_name[35]` up to its first NUL.
    function_name: Vec<u8>,
}

impl CNondetCall {
    /// `new_nondet_call` (`NonDetLog.c:117-142`) with the value already in
    /// its union bits: the name is cut at [`FUNCTION_MAX_LENGTH_NAME`] bytes
    /// (`strncpy`), and the bits above the stored member stay zero
    /// (`memset`).
    pub fn from_parts(
        kind: i32,
        line: u32,
        scope: u32,
        step: u32,
        function_name: &[u8],
        value: u64,
    ) -> Self {
        let name = function_name
            .iter()
            .take(FUNCTION_MAX_LENGTH_NAME)
            .take_while(|&&b| b != 0)
            .copied()
            .collect();
        Self {
            kind,
            line,
            scope,
            step,
            value,
            function_name: name,
        }
    }

    /// The union bits: the `int` member zero-extended for the 32-bit types,
    /// the 64-bit patterns of `double` (DOUBLE, FLOAT), `long long` and
    /// `unsigned long long`.
    pub fn value_bits(&self) -> u64 {
        self.value
    }

    pub fn function_name(&self) -> &[u8] {
        &self.function_name
    }

    /// One row of `klee_log.csv` (`NonDetLog.c:68-112`):
    /// `index;line;scope;function;step;value;type\n`.
    pub fn csv_row(&self, index: usize) -> Vec<u8> {
        let mut row = Vec::with_capacity(64);
        // `put_longlong(end, (int)i)`.
        row.extend_from_slice((index as i32).to_string().as_bytes());
        row.push(b';');
        row.extend_from_slice(self.line.to_string().as_bytes());
        row.push(b';');
        row.extend_from_slice(self.scope.to_string().as_bytes());
        row.push(b';');
        row.extend_from_slice(&self.function_name);
        row.push(b';');
        row.extend_from_slice(self.step.to_string().as_bytes());
        row.push(b';');
        let value = match self.kind {
            // `as_unsigned`, printed once (`:91-92`).
            kind::UNSIGNED | kind::U32 => (self.value as u32).to_string(),
            kind::DOUBLE => crate::output::legacy_files::c_double(f64::from_bits(self.value)),
            kind::FLOAT => c_float_g9(f64::from_bits(self.value) as f32),
            kind::LONGLONG => (self.value as i64).to_string(),
            kind::ULONGLONG => self.value.to_string(),
            // `as_int`.
            _ => (self.value as u32 as i32).to_string(),
        };
        row.extend_from_slice(value.as_bytes());
        row.push(b';');
        row.extend_from_slice(self.kind.to_string().as_bytes());
        row.push(b'\n');
        row
    }
}

/// `printf("%.9g", value)` of glibc (`NonDetLog.c:99`).
pub fn c_float_g9(value: f32) -> String {
    if value.is_nan() {
        return if value.is_sign_negative() {
            "-nan"
        } else {
            "nan"
        }
        .to_owned();
    }
    if value.is_infinite() {
        return if value < 0.0 { "-inf" } else { "inf" }.to_owned();
    }
    if value == 0.0 {
        return if value.is_sign_negative() { "-0" } else { "0" }.to_owned();
    }
    let wide = f64::from(value);
    // Nine significant digits: the exponent X is the one after rounding.
    let scientific = format!("{wide:.8e}");
    let (mantissa, exponent) = scientific.split_once('e').unwrap_or((&scientific, "0"));
    let exponent: i32 = exponent.parse().unwrap_or(0);
    let strip = |text: &str| -> String {
        if text.contains('.') {
            text.trim_end_matches('0').trim_end_matches('.').to_owned()
        } else {
            text.to_owned()
        }
    };
    if !(-4..9).contains(&exponent) {
        let sign = if exponent < 0 { '-' } else { '+' };
        format!("{}e{sign}{:02}", strip(mantissa), exponent.abs())
    } else {
        let decimals = usize::try_from(8 - exponent).unwrap_or(0);
        strip(&format!("{wide:.decimals$}"))
    }
}

/// `nondet_log_to_file` (`NonDetLog.c:50-125`): writes every row to
/// `dir/klee_log.csv`, creating the file even for an empty log. Returns
/// `FALSE` when the file cannot be written.
pub fn nondet_log_to_file(rows: &[CNondetCall], dir: &Path) -> bool {
    let mut out = Vec::new();
    for (i, row) in rows.iter().enumerate() {
        out.extend_from_slice(&row.csv_row(i));
    }
    crate::output::legacy_files::write_atomic_bytes(dir, KLEE_LOG_FILE, &out).is_ok()
}
