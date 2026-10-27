# SPDX-License-Identifier: GPL-3.0-only
"""Tests of the D7 post-processing helpers of the drop-in core
(build-test-runtime-bc.sh): stub_personality.py, drop_dwarf_flag.py and the
check_no_freeze.py guard. Run: python3 -I -m unittest discover -s scripts/runtime-ir
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import drop_dwarf_flag  # noqa: E402
import check_no_freeze  # noqa: E402
import stub_personality  # noqa: E402

TRIPLE = 'target triple = "x86_64-pc-linux-gnu"\n'


def clang_accepts(ir):
    """clang -c -x ir: the text is valid IR (skipped where clang is missing)."""
    tmp = tempfile.mkdtemp()
    path = os.path.join(tmp, "m.ll")
    with open(path, "w") as f:
        f.write(ir)
    r = subprocess.run(["clang", "--target=x86_64-pc-linux-gnu", "-w", "-c", "-x", "ir", path,
                        "-o", os.devnull], capture_output=True, text=True)
    return r.returncode == 0, r.stderr


class StubPersonality(unittest.TestCase):
    SRC = TRIPLE + ("declare i32 @_Unwind_RaiseException(ptr)\n\n"
                    "define i32 @rust_eh_personality(i32 %a, ptr %b) unnamed_addr {\nstart:\n"
                    "  %r = call i32 @_Unwind_RaiseException(ptr %b)\n  ret i32 %r\n}\n")

    def test_body_becomes_abort(self):
        out = stub_personality.stub(self.SRC)
        body = out.split("@rust_eh_personality(", 1)[1].split("\n}\n", 1)[0]
        self.assertIn("call void @abort()", body)
        self.assertIn("unreachable", body)
        self.assertNotIn("_Unwind_RaiseException(ptr %b)", body)
        self.assertIn("declare void @abort()", out)

    def test_missing_personality_is_an_error(self):
        with self.assertRaises(ValueError):
            stub_personality.stub(TRIPLE + "define void @f() {\n  ret void\n}\n")

    @unittest.skipUnless(shutil.which("clang"), "clang not installed")
    def test_output_is_valid_ir(self):
        ok, err = clang_accepts(stub_personality.stub(self.SRC))
        self.assertTrue(ok, err)


class DropDwarfFlag(unittest.TestCase):
    def test_flag_and_its_reference_go(self):
        src = (TRIPLE + "define void @f() {\n  ret void\n}\n"
               '!llvm.module.flags = !{!0, !1, !2}\n'
               '!0 = !{i32 7, !"PIC Level", i32 2}\n'
               '!1 = !{i32 7, !"Dwarf Version", i32 4}\n'
               '!2 = !{i32 2, !"RtLibUseGOT", i32 1}\n')
        out = drop_dwarf_flag.drop(src)
        self.assertNotIn("Dwarf Version", out)
        self.assertIn("!llvm.module.flags = !{!0, !2}\n", out)

    def test_module_without_the_flag_is_unchanged(self):
        src = TRIPLE + "define void @f() {\n  ret void\n}\n"
        self.assertEqual(drop_dwarf_flag.drop(src), src)


class CheckNoFreeze(unittest.TestCase):
    SRC = (TRIPLE + "define i64 @f(i64 %x) {\n  %a = freeze i64 %x\n  %b = freeze i64 %a\n  ret i64 %b\n}\n\n"
           "define void @\"quoted name\"(i1 %c) {\n  %d = freeze i1 %c\n  ret void\n}\n\n"
           "define i64 @g(i64 %x) {\n  ; freeze i64 %x\n  ret i64 %x\n}\n")

    def test_names_each_function_that_keeps_a_freeze(self):
        self.assertEqual(check_no_freeze.functions_with_freeze(self.SRC), {"f": 2, "quoted name": 1})

    def test_module_without_freeze_passes(self):
        self.assertEqual(check_no_freeze.functions_with_freeze(
            TRIPLE + "define i64 @g(i64 %x) {\n  ret i64 %x\n}\n"), {})

    def test_command_line_fails_and_names_the_function(self):
        tmp = tempfile.mkdtemp()
        path = os.path.join(tmp, "m.ll")
        with open(path, "w") as f:
            f.write(self.SRC)
        r = subprocess.run([sys.executable, "-I", os.path.join(HERE, "check_no_freeze.py"), path],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)
        self.assertIn("2  f", r.stderr)
        self.assertIn("1  quoted name", r.stderr)
        with open(path, "w") as f:
            f.write(TRIPLE + "define void @h() {\n  ret void\n}\n")
        r = subprocess.run([sys.executable, "-I", os.path.join(HERE, "check_no_freeze.py"), path],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)


if __name__ == "__main__":
    unittest.main()
