# SPDX-License-Identifier: GPL-3.0-only
"""Tests of the D7 post-processing helpers of the drop-in core
(build-test-runtime-bc.sh): stub_personality.py, drop_dwarf_flag.py and
lower_freeze.py. Run: python3 -I -m unittest discover -s scripts/runtime-ir
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
import lower_freeze  # noqa: E402
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


class LowerFreeze(unittest.TestCase):
    def test_scalar_and_pointer_freeze_become_identity_bitcasts(self):
        src = ("  %a = freeze i64 %x\n  %b.c = freeze i1 %y, !noundef !3\n"
               "  %p = freeze ptr %q\n  %v = freeze <2 x i64> %w\n")
        out, n = lower_freeze.lower(src)
        self.assertEqual(n, 4)
        self.assertEqual(out, ("  %a = bitcast i64 %x to i64\n  %b.c = bitcast i1 %y to i1, !noundef !3\n"
                               "  %p = bitcast ptr %q to ptr\n  %v = bitcast <2 x i64> %w to <2 x i64>\n"))
        self.assertEqual(lower_freeze.remaining(out), [])

    def test_other_lines_are_untouched(self):
        src = "  %a = add i64 %x, 1\n  ; freeze i64 %x\n"
        self.assertEqual(lower_freeze.lower(src), (src, 0))

    def test_aggregate_or_constant_expression_is_an_error(self):
        for line in ("  %a = freeze { i64, i64 } %s", "  %a = freeze i64 ptrtoint (ptr @g to i64)"):
            with self.assertRaises(ValueError, msg=line):
                lower_freeze.lower(line)

    def test_check_finds_what_is_left(self):
        self.assertEqual(lower_freeze.remaining("  %a = freeze i32 %b\n"), ["%a = freeze i32 %b"])

    @unittest.skipUnless(shutil.which("clang"), "clang not installed")
    def test_lowered_module_is_valid_ir(self):
        src = (TRIPLE + "define i64 @f(i64 %x, i1 %c, ptr %p) {\n"
               "  %a = freeze i64 %x\n  %b = freeze i1 %c\n  %q = freeze ptr %p\n"
               "  %s = select i1 %b, i64 %a, i64 0\n  ret i64 %s\n}\n")
        out, n = lower_freeze.lower(src)
        self.assertEqual(n, 3)
        ok, err = clang_accepts(out)
        self.assertTrue(ok, err)


if __name__ == "__main__":
    unittest.main()
