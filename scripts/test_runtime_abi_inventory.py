# SPDX-License-Identifier: GPL-3.0-only
"""Tests for scripts/runtime-abi-inventory.py.

Run with: python3 -I -m unittest scripts/test_runtime_abi_inventory.py
"""

import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "runtime-abi-inventory.py")
TOOLS = ("clang", "nm", "ar")


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(textwrap.dedent(text).lstrip("\n"))


def build_fixture(root):
    """A minimal Map2Check tree: two runtime .c, one header, one pass, one frontend file."""
    lib = os.path.join(root, "modules", "backend", "library")
    write(os.path.join(lib, "header", "Fix.h"), """
        int map2check_x(int a, const char *s);
        extern int shared_counter;
        void helper(void);
        """)
    write(os.path.join(lib, "lib", "A.c"), """
        #include "../header/Fix.h"
        int shared_counter = 0;
        static int hidden(void) { return 3; }
        int map2check_x(int a, const char *s) { helper(); return a + hidden() + (s != 0); }
        int map2check_non_det_int(void) { return 1; }
        unsigned map2check_non_det_unsigned(void) { return 2u; }
        """)
    write(os.path.join(lib, "lib", "B.c"), """
        #include "../header/Fix.h"
        void helper(void) {}
        int map2check_non_det_int(void) { return 0; }
        long unused_fn(long x) { return x; }
        """)
    write(os.path.join(root, "modules", "backend", "pass", "P.cpp"), """
        // unused_fn is only mentioned in a comment and must not count.
        /* "unused_fn" neither. */
        void P::setup(Function &F) {
          auto x = F.getParent()->getOrInsertFunction("map2check_x", I32, PtrTy);
          auto m = F.getParent()->getOrInsertFunction("map2check_missing", VoidTy);
        }
        #define CALL_IF_HELPER(type, nondet_type, c_type)                             \\
          if ((calleeFunction->getName() == ("__VERIFIER_nondet_" #c_type))) {        \\
            this->instrumentNonDet(NonDetType::nondet_type, calleeFunction);          \\
          } else if ((calleeFunction->getName() == ("map2check_non_det_" #c_type))) { \\
            this->instrumentNonDet##type(callInst, Ctx);                              \\
          }
        void P::run(CallInst *callInst) {
          CALL_IF_HELPER(Integer, INTEGER, int)
          CALL_IF_HELPER(Unsigned, UNSIGNED, unsigned)
        }
        """)
    write(os.path.join(root, "modules", "frontend", "F.cpp"), """
        std::string counter = "shared_counter";
        """)


def build_rust_side(root, work):
    """A stand-in for libmap2check.a and include/map2check.h."""
    header = os.path.join(root, "rust", "map2check.h")
    write(header, """
        int map2check_x(int a, const char *s);
        long map2check_non_det_int(void);
        """)
    source = os.path.join(work, "rustlib.c")
    write(source, """
        int map2check_x(int a, const char *s) { return a + (s != 0); }
        long map2check_non_det_int(void) { return 0; }
        """)
    obj = os.path.join(work, "rustlib.o")
    archive = os.path.join(root, "rust", "libfake.a")
    subprocess.run(["clang", "-w", "-c", "-o", obj, source], check=True)
    subprocess.run(["ar", "rcs", archive, obj], check=True)
    return archive, header


def read_lines(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read().splitlines()


@unittest.skipUnless(all(shutil.which(t) for t in TOOLS), "needs clang, nm and ar")
class InventoryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = os.path.join(self.tmp.name, "map2check")
        self.out = os.path.join(self.tmp.name, "out")
        build_fixture(self.root)
        self.archive, self.header = build_rust_side(self.root, self.tmp.name)
        self.result = subprocess.run(
            [sys.executable, "-I", SCRIPT,
             "--map2check", self.root, "--out-dir", self.out,
             "--rust-lib", self.archive, "--rust-header", self.header],
            capture_output=True, text=True)

    def tearDown(self):
        self.tmp.cleanup()

    def test_exit_status(self):
        self.assertEqual(self.result.returncode, 0, self.result.stderr)

    def test_inventory_rows(self):
        self.assertEqual(read_lines(os.path.join(self.out, "inventory.tsv")), [
            "symbol\tkind\tsignature\tmodule\treferenced_by",
            "helper\tfunc\tvoid (void)\tB.bc\truntime",
            "map2check_non_det_int\tfunc\tint (void)\tA.bc+B.bc\tpass",
            "map2check_non_det_unsigned\tfunc\tunsigned int (void)\tA.bc\tpass",
            "map2check_x\tfunc\tint (int, const char *)\tA.bc\tpass",
            "shared_counter\tdata\tint\tA.bc\tfrontend",
            "unused_fn\tfunc\tlong (long)\tB.bc\t-",
        ])

    def test_rust_gap_rows(self):
        self.assertEqual(read_lines(os.path.join(self.out, "rust-gap.tsv")), [
            "symbol\tstatus\trust_signature",
            "helper\tmissing\t-",
            "map2check_non_det_int\tdifferent\tlong (void)",
            "map2check_non_det_unsigned\tmissing\t-",
            "map2check_x\tsame\tint (int, const char *)",
            "shared_counter\tmissing\t-",
            "unused_fn\tmissing\t-",
        ])

    def test_reports_unresolved_pass_names(self):
        self.assertIn("map2check_missing", self.result.stdout)
        self.assertIn("__VERIFIER_nondet_unsigned", self.result.stdout)
        self.assertIn("defined: 6", self.result.stdout)


if __name__ == "__main__":
    unittest.main()
