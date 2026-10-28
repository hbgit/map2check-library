#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Test only: gives a copy of the drop-in core's IR (Map2CheckFunctions.bc,
disassembled) a C entry point that panics, `void m2c_test_panic(long index)`,
so scripts/runtime-ir/test-klee-generator.sh can check that a Rust panic
under KLEE ends its path with an abort and runs no backtrace-symbolizer code
(D7 post-processing: the symbolizer is stubbed, and std's
rust_panic_with_hook is an abort stub, approved 2026-10-27). The runtime
denies panics outside tests, so no C API function reaches one. Ported from
tests/klee/panic_shim.py of the legacy KLEE route (removed in Task 2.10).

The entry point calls `core::panicking::panic_bounds_check(index, 4, loc)`
with the `Location` of an existing call site: the real path through the
panic handler to the hook.

Usage: panic_shim.py <core.ll> <out.ll>"""
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
