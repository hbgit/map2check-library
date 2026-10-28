# SPDX-License-Identifier: GPL-3.0-only
"""Tests of gen_ll.py (D7 spike). Run: python3 -I -m unittest discover -s spikes/d7-layout/scripts"""
import csv
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
INVENTORY = os.path.join(ROOT, "docs", "runtime-abi", "inventory.tsv")
sys.path.insert(0, HERE)
import gen_ll  # noqa: E402

HEAD = "symbol\tkind\tsignature\tcanonical_signature\tmodule\treferenced_by\n"


def defined(ll_text):
    return {line.split("@", 1)[1].split("(", 1)[0]
            for line in ll_text.splitlines() if line.startswith("define ")}


class ParseSig(unittest.TestCase):
    def test_enum_is_i32(self):
        self.assertEqual(gen_ll.parse_sig("void (enum wasm_rt_trap_t)"), ("void", ["i32"]))

    def test_pointer_return_without_space(self):
        self.assertEqual(gen_ll.parse_sig("void *(void)"), ("ptr", []))
        self.assertEqual(gen_ll.parse_sig("struct obj2 *(struct obj4 *, void *)"), ("ptr", ["ptr", "ptr"]))

    def test_struct_by_value_is_an_error(self):
        with self.assertRaises(gen_ll.StructByValue):
            gen_ll.parse_sig("struct obj4 (void)")

    def test_unknown_type_is_an_error(self):
        with self.assertRaises(ValueError):
            gen_ll.parse_sig("void (__int128)")


class LoadInventory(unittest.TestCase):
    def write(self, rows):
        f = tempfile.NamedTemporaryFile("w", suffix=".tsv", delete=False)
        f.write(HEAD + "".join("\t".join(r) + "\n" for r in rows))
        f.close()
        self.addCleanup(os.unlink, f.name)
        return f.name

    def test_unparseable_signature_outside_the_exemptions_fails(self):
        path = self.write([["m2c_x", "func", "s", "struct obj9 (int)", "AnalysisModeNone.bc", "pass"]])
        with self.assertRaises(SystemExit) as e:
            gen_ll.load_inventory(path)
        self.assertIn("m2c_x", str(e.exception.code))

    def test_exempt_struct_by_value_is_skipped(self):
        path = self.write([["new_container", "func", "s", "struct obj4 (enum Container_Type)",
                            "ContainerRealloc.bc", "runtime"]])
        self.assertEqual(gen_ll.load_inventory(path), {})

    def test_exemptions_are_all_struct_by_value_runtime_helpers(self):
        rows = {r["symbol"]: r for r in csv.DictReader(open(INVENTORY), delimiter="\t")}
        for sym in gen_ll.STRUCT_BY_VALUE_EXEMPT:
            self.assertIn(sym, rows)
            self.assertEqual(rows[sym]["referenced_by"], "runtime", sym)
            with self.assertRaises(gen_ll.StructByValue, msg=sym):
                gen_ll.parse_sig(rows[sym]["canonical_signature"])


class Generated(unittest.TestCase):
    def test_wasm_stubs_define_every_c_function(self):
        out = tempfile.mkdtemp()
        subprocess.run([sys.executable, "-I", os.path.join(HERE, "gen_ll.py"), "fwd", INVENTORY, out],
                       check=True)
        want = {r["symbol"] for r in csv.DictReader(open(INVENTORY), delimiter="\t")
                if r["module"] == "WasmRuntimeStubs.bc" and r["kind"] == "func"}
        self.assertEqual(len(want), 10)
        got = defined(open(os.path.join(out, "WasmRuntimeStubs.ll")).read())
        self.assertEqual(got, want)
        self.assertIn("define void @wasm_rt_trap(i32 %a0)", open(os.path.join(out, "WasmRuntimeStubs.ll")).read())


if __name__ == "__main__":
    unittest.main()
