# SPDX-License-Identifier: GPL-3.0-only
"""Tests for scripts/runtime-abi-inventory.py.

Run from the repository root with:

    python3 -I -m unittest discover -s scripts -p test_runtime_abi_inventory.py

(`python3 -I -m unittest scripts/test_runtime_abi_inventory.py` does not work:
-I drops the current directory from sys.path, so the module cannot be found.)
"""

import importlib.util
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
        typedef int bool;
        typedef void *pointer;
        typedef struct { int a; } ANON;
        typedef struct NAMED { int b; } NAMED;
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
        bool map2check_non_det_bool(void) { return 1; }
        pointer map2check_ptr() { return 0; }
        ANON take_anon(ANON a, NAMED *n, const pointer p) { (void)n; (void)p; return a; }
        """)
    write(os.path.join(lib, "lib", "B.c"), """
        #include "../header/Fix.h"
        void helper(void) {}
        int map2check_non_det_int(void) { return 0; }
        long unused_fn(long x) { return x; }
        """)
    write(os.path.join(lib, "lib", "W.c"), """
        #include <stdbool.h>
        int __afl_sharedmem_fuzzing = 1;
        bool wasm_rt_is_initialized(void) { return 1; }
        void w2c_env_exit(int code) { (void)code; }
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
          CALL_IF_HELPER(Bool, BOOL, bool)
          auto p = F.getParent()->getOrInsertFunction("map2check_ptr", PtrTy);
        }
        """)
    write(os.path.join(root, "modules", "frontend", "F.cpp"), """
        std::string counter = "shared_counter";
        """)


def build_rust_side(root, work):
    """A stand-in for libmap2check.a and include/map2check.h."""
    header = os.path.join(root, "rust", "map2check.h")
    write(header, """
        #include <stdbool.h>
        #include <stdint.h>
        int32_t map2check_x(int32_t a, const char *s);
        long map2check_non_det_int(void);
        bool map2check_non_det_bool(void);
        void *map2check_ptr(void);
        """)
    source = os.path.join(work, "rustlib.c")
    write(source, """
        #include <stdbool.h>
        int map2check_x(int a, const char *s) { return a + (s != 0); }
        long map2check_non_det_int(void) { return 0; }
        bool map2check_non_det_bool(void) { return 1; }
        void *map2check_ptr(void) { return 0; }
        bool wasm_rt_is_initialized(void) { return 1; }
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
        self.maxDiff = None
        self.assertEqual(read_lines(os.path.join(self.out, "inventory.tsv")), [
            "symbol\tkind\tsignature\tcanonical_signature\tmodule\treferenced_by",
            "__afl_sharedmem_fuzzing\tdata\tint\tint\tW.bc\texternal",
            "helper\tfunc\tvoid (void)\tvoid (void)\tB.bc\truntime",
            "map2check_non_det_bool\tfunc\tbool (void)\tint (void)\tA.bc\tpass",
            "map2check_non_det_int\tfunc\tint (void)\tint (void)\tA.bc+B.bc\tpass",
            "map2check_non_det_unsigned\tfunc\tunsigned int (void)\tunsigned int (void)\tA.bc\tpass",
            "map2check_ptr\tfunc\tpointer ()\tvoid *(void)\tA.bc\tpass",
            "map2check_x\tfunc\tint (int, const char *)\tint (int, const char *)\tA.bc\tpass",
            "shared_counter\tdata\tint\tint\tA.bc\tfrontend",
            "take_anon\tfunc\tANON (ANON, NAMED *, const pointer)"
            "\tstruct ANON (struct ANON, struct NAMED *, void *const)\tA.bc\t-",
            "unused_fn\tfunc\tlong (long)\tlong (long)\tB.bc\t-",
            "w2c_env_exit\tfunc\tvoid (int)\tvoid (int)\tW.bc\texternal",
            "wasm_rt_is_initialized\tfunc\tbool (void)\t_Bool (void)\tW.bc\texternal",
        ])

    def test_rust_gap_rows(self):
        self.assertEqual(read_lines(os.path.join(self.out, "rust-gap.tsv")), [
            "symbol\tstatus\trust_signature\trust_canonical_signature",
            "__afl_sharedmem_fuzzing\tmissing\t-\t-",
            "helper\tmissing\t-\t-",
            "map2check_non_det_bool\tdifferent\t_Bool (void)\t_Bool (void)",
            "map2check_non_det_int\tdifferent\tlong (void)\tlong (void)",
            "map2check_non_det_unsigned\tmissing\t-\t-",
            "map2check_ptr\tsame\tvoid *(void)\tvoid *(void)",
            "map2check_x\tsame\tint32_t (int32_t, const char *)\tint (int, const char *)",
            "shared_counter\tmissing\t-\t-",
            "take_anon\tmissing\t-\t-",
            "unused_fn\tmissing\t-\t-",
            "w2c_env_exit\tmissing\t-\t-",
            "wasm_rt_is_initialized\tundeclared\t-\t-",
        ])

    def test_reports_unresolved_pass_names(self):
        self.assertIn("map2check_missing", self.result.stdout)
        self.assertIn("__VERIFIER_nondet_unsigned", self.result.stdout)
        self.assertIn("defined: 12", self.result.stdout)


class CanonicalizerTest(unittest.TestCase):
    """The type printer must reproduce clang's spelling when no typedef is involved."""

    def setUp(self):
        spec = importlib.util.spec_from_file_location("inventory", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.module = module

    def test_round_trip_without_typedefs(self):
        canon = self.module.Canonicalizer({})
        for text in ("void (*)(int)", "int (*(*)(void))[3]", "const char *const *",
                     "unsigned char[1048576]", "void *(unsigned int, struct X)",
                     "char **(void)", "int (int, char **)", "enum E (union U *)"):
            self.assertEqual(canon.canonical(text), text)

    def test_typedefs_resolved(self):
        canon = self.module.Canonicalizer({
            "pointer": "void *", "u8": "unsigned char", "ROW": "struct ROW",
            "ROWP": "ROW *", "bool": "int"})
        self.assertEqual(canon.canonical("const pointer"), "void *const")
        self.assertEqual(canon.canonical("ROWP (const u8 *, bool)"),
                         "struct ROW *(const unsigned char *, int)")
        self.assertEqual(self.module.canonical_signature(canon, "func", "pointer ()"), "void *(void)")
        self.assertEqual(self.module.Canonicalizer({}).canonical("bool (void)"), "_Bool (void)")


@unittest.skipUnless(all(shutil.which(t) for t in TOOLS), "needs clang, nm and ar")
class MissingDeclarationTest(unittest.TestCase):
    def test_symbol_without_declaration_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = os.path.join(tmp, "map2check")
            build_fixture(root)
            archive, header = build_rust_side(root, tmp)
            write(os.path.join(root, "modules", "backend", "library", "lib", "Asm.c"), """
                __asm__(".globl asm_only\\nasm_only:\\n  ret\\n");
                """)
            result = subprocess.run(
                [sys.executable, "-I", SCRIPT, "--map2check", root,
                 "--out-dir", os.path.join(tmp, "out"),
                 "--rust-lib", archive, "--rust-header", header],
                capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("asm_only", result.stderr)
            self.assertIn("Asm.c", result.stderr)
            self.assertFalse(os.path.exists(os.path.join(tmp, "out", "inventory.tsv")))


if __name__ == "__main__":
    unittest.main()
