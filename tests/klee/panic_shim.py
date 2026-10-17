#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Test only: gives a copy of the KLEE runtime's IR a C entry point that
panics, `void m2c_test_panic(long index)`, so tests/klee_paths.sh can check
that a panic still ends its path (a KLEE error, not a hang) after the backtrace
symbolizer was stubbed out (scripts/klee-stub-symbolizer.py). The runtime
denies panics outside tests, so no C API function reaches one.

The entry point calls `core::panicking::panic_bounds_check(index, 4, loc)`
with the `Location` of an existing call site: the real path through the
panic handler, std's default hook (which prints a backtrace when
RUST_BACKTRACE is set) and panic = "abort".

Usage: panic_shim.py <runtime.ll> <out.ll>"""
import re
import sys

CALL = re.compile(
    r"call fastcc void @(?P<f>_ZN4core9panicking18panic_bounds_check17h[0-9a-f]+E)"
    r"\(i64 [^,]*, i64 [^,]*, ptr [^@%]*(?P<loc>@[-\w.$]+)\)"
)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1]) as f:
        ir = f.read()
    m = CALL.search(ir)
    if not m:
        sys.exit("panic_shim: no call to core::panicking::panic_bounds_check in the module")
    with open(sys.argv[2], "w") as f:
        f.write(ir)
        f.write(
            "\ndefine void @m2c_test_panic(i64 %i) {\n"
            f"  call fastcc void @{m['f']}(i64 %i, i64 4, ptr {m['loc']})\n"
            "  unreachable\n}\n"
        )


if __name__ == "__main__":
    main()
