# SPDX-License-Identifier: GPL-3.0-only
"""Tests of gen_ll.py. Run: python3 -I -m unittest discover -s scripts/runtime-ir

Promoted with the generator from the D7 spike (spikes/d7-layout/scripts/
test_gen_ll.py); the ParseSig/LoadInventory/wasm tests are the spike's.
"""
import csv
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
INVENTORY = os.path.join(ROOT, "docs", "runtime-abi", "inventory.tsv")
FFI_RS = os.path.join(ROOT, "rust", "src", "ffi.rs")
GEN = os.path.join(HERE, "gen_ll.py")
sys.path.insert(0, HERE)
import gen_ll  # noqa: E402

HEAD = "symbol\tkind\tsignature\tcanonical_signature\tmodule\treferenced_by\n"

# The 20 modules that are not the Rust core, plus the IR part of the core.
ALL_MODULES = {
    "Map2CheckFunctions-glue", "TrackBBLog", "NonDetLog", "PropertyGenerator",
    "ContainerRealloc", "ContainerBTree", "BTree", "AllocationLog", "ListLog",
    "HeapLog", "AnalysisModeMemtrack", "AnalysisModeMemcleanup",
    "AnalysisModeOverflow", "AnalysisModeAssert", "AnalysisModeNone",
    "WasmRuntimeStubs", "WitnessGeneration", "WitnessGenerationNone",
    "NonDetGeneratorNone", "NonDetGeneratorKlee", "NonDetGeneratorAFL",
}


def defined(ll_text):
    return {line.split("@", 1)[1].split("(", 1)[0]
            for line in ll_text.splitlines() if line.startswith("define ")}


def run_gen(*args):
    out = tempfile.mkdtemp()
    subprocess.run([sys.executable, "-I", GEN, *args, INVENTORY, out], check=True)
    return out


def read(path):
    with open(path) as f:
        return f.read()


def inventory_rows():
    with open(INVENTORY, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


EXT = ("signext", "zeroext")


def abi_of(line):
    """'define dso_local signext i8 @f(i8 noundef zeroext %0, ptr %1) #0 {'
    -> (name, (ret_type, ret_ext), [(type, ext), ...]); ext is None or one of
    EXT. Works for define and declare lines of clang and of gen_ll."""
    head, rest = line.split("@", 1)
    name, params = rest.split("(", 1)
    params = params.rsplit(")", 1)[0]
    words = head.split()[1:]
    ret_ext = next((w for w in words if w in EXT), None)
    ret_type = [w for w in words if w not in EXT and w not in ("dso_local", "noundef")][-1]
    args = []
    for p in params.split(", ") if params.strip() else []:
        ws = [w for w in p.split() if not w.startswith("%")]
        ext = next((w for w in ws if w in EXT), None)
        args.append((ws[0], ext))
    return name, (ret_type, ret_ext), args


class ParseSig(unittest.TestCase):
    def test_enum_is_i32(self):
        self.assertEqual(gen_ll.parse_sig("void (enum wasm_rt_trap_t)"),
                         (("void", None), [("i32", None)]))

    def test_pointer_return_without_space(self):
        self.assertEqual(gen_ll.parse_sig("void *(void)"), (("ptr", None), []))
        self.assertEqual(gen_ll.parse_sig("struct obj2 *(struct obj4 *, void *)"),
                         (("ptr", None), [("ptr", None), ("ptr", None)]))

    def test_struct_by_value_is_an_error(self):
        with self.assertRaises(gen_ll.StructByValue):
            gen_ll.parse_sig("struct obj4 (void)")

    def test_unknown_type_is_an_error(self):
        with self.assertRaises(ValueError):
            gen_ll.parse_sig("void (__int128)")


class AbiAttributes(unittest.TestCase):
    """D7 inherited finding 4: the x86_64 SysV attributes clang-16 puts on
    char/short/_Bool parameters and returns."""

    def test_small_signed_types_are_signext(self):
        for c in ("char", "signed char", "short", "const char"):
            self.assertEqual(gen_ll.parse_sig(f"{c} ({c})")[0][1], "signext", c)
            self.assertEqual(gen_ll.parse_sig(f"void ({c})")[1], [(gen_ll.ir_type(c)[0], "signext")], c)

    def test_small_unsigned_types_are_zeroext(self):
        for c in ("unsigned char", "unsigned short"):
            self.assertEqual(gen_ll.parse_sig(f"{c} ({c})")[0][1], "zeroext", c)
            self.assertEqual(gen_ll.parse_sig(f"void ({c})")[1][0][1], "zeroext", c)

    def test_bool_is_zeroext_i1(self):
        self.assertEqual(gen_ll.parse_sig("_Bool (_Bool)"), (("i1", "zeroext"), [("i1", "zeroext")]))

    def test_wide_types_have_no_attribute(self):
        self.assertEqual(gen_ll.parse_sig("long long (int, unsigned int, double, char *)"),
                         (("i64", None), [("i32", None), ("i32", None), ("double", None), ("ptr", None)]))

    def test_forwarder_carries_attributes_on_definition_declaration_and_call(self):
        text = gen_ll.forwarder("f", ("i8", "signext"), [("ptr", None), ("i8", "signext")], "__m2c_rt_f")
        self.assertIn("declare signext i8 @__m2c_rt_f(ptr, i8 signext)\n", text)
        self.assertIn("define signext i8 @f(ptr %a0, i8 signext %a1) {\n", text)
        self.assertIn("  %r = tail call signext i8 @__m2c_rt_f(ptr %a0, i8 signext %a1)\n", text)
        self.assertIn("  ret i8 %r\n", text)

    def test_stub_return_uses_the_bare_type(self):
        text = gen_ll.stub("analysis_is_program_correct", ("i8", "signext"), [])
        self.assertEqual(text, "define signext i8 @analysis_is_program_correct() {\n  ret i8 1\n}\n\n")

    @unittest.skipUnless(shutil.which("clang"), "clang not installed")
    def test_every_generated_function_matches_clang_x86_64(self):
        """Each function gen_ll defines has the IR types and ext attributes
        clang gives a C definition with the inventory's canonical signature."""
        out = run_gen()
        ours = {}
        for name in os.listdir(out):
            for line in read(os.path.join(out, name)).splitlines():
                if line.startswith("define ") and "internal" not in line.split("@")[0]:
                    sym, ret, args = abi_of(line)
                    ours[sym] = (ret, args)
        src, structs = [], set()
        seen = set()
        for r in inventory_rows():
            sym, sig = r["symbol"], r["canonical_signature"].split(" | ")[0]
            if r["kind"] != "func" or sym in seen or sym not in ours or sym == "main":
                continue
            seen.add(sym)
            sig = re.sub(r"\benum \w+", "int", sig)
            structs.update(re.findall(r"\b(?:struct|union) \w+", sig))
            ret, args = sig.split("(", 1)
            args = args.rsplit(")", 1)[0].strip()
            params = "void" if args in ("", "void") else ", ".join(
                f"{a} p{i}" for i, a in enumerate(args.split(", ")))
            body = "" if ret.strip() == "void" else "return 0;"
            src.append(f"{ret.strip()} {sym}({params}) {{ {body} }}")
        c = "".join(f"{s};\n" for s in sorted(structs)) + "\n".join(src) + "\n"
        tmp = tempfile.mkdtemp()
        with open(os.path.join(tmp, "sigs.c"), "w") as f:
            f.write(c)
        ll = subprocess.run(["clang", "-O0", "-w", "-S", "-emit-llvm", "--target=x86_64-pc-linux-gnu",
                             os.path.join(tmp, "sigs.c"), "-o", "-"],
                            check=True, capture_output=True, text=True).stdout
        theirs = {}
        for line in ll.splitlines():
            if line.startswith("define "):
                sym, ret, args = abi_of(line)
                theirs[sym] = (ret, args)
        self.assertEqual(set(theirs), seen)
        for sym in sorted(seen):
            self.assertEqual(ours[sym], theirs[sym], sym)
        # The signatures finding 4 named, and the generators' small types.
        for sym in ("analysis_is_program_correct", "map2check_crab_assume", "map2check_assume_loop",
                    "generate_aux_files", "map2check_non_det_char", "map2check_non_det_u8",
                    "map2check_non_det_ushort", "wasm_rt_is_initialized", "wasm_rt_allocate_memory"):
            self.assertIn(sym, seen)


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
        rows = {r["symbol"]: r for r in inventory_rows()}
        for sym in gen_ll.STRUCT_BY_VALUE_EXEMPT:
            self.assertIn(sym, rows)
            self.assertEqual(rows[sym]["referenced_by"], "runtime", sym)
            with self.assertRaises(gen_ll.StructByValue, msg=sym):
                gen_ll.parse_sig(rows[sym]["canonical_signature"])


class Generated(unittest.TestCase):
    def test_wasm_stubs_define_every_c_function(self):
        out = run_gen()
        want = {r["symbol"] for r in inventory_rows()
                if r["module"] == "WasmRuntimeStubs.bc" and r["kind"] == "func"}
        self.assertEqual(len(want), 10)
        text = read(os.path.join(out, "WasmRuntimeStubs.ll"))
        self.assertEqual(defined(text), want)
        self.assertIn("define void @wasm_rt_trap(i32 %a0)", text)

    def test_writes_every_module_once(self):
        out = run_gen()
        self.assertEqual({n[:-3] for n in os.listdir(out)}, ALL_MODULES)

    def test_output_is_deterministic(self):
        a, b = run_gen(), run_gen()
        for name in sorted(os.listdir(a)):
            self.assertEqual(read(os.path.join(a, name)), read(os.path.join(b, name)), name)

    def test_module_option_writes_only_that_module(self):
        full = run_gen()
        for m in ("AnalysisModeOverflow", "NonDetGeneratorAFL", "Map2CheckFunctions-glue", "BTree"):
            one = run_gen("--module", m)
            self.assertEqual(os.listdir(one), [m + ".ll"], m)
            self.assertEqual(read(os.path.join(one, m + ".ll")), read(os.path.join(full, m + ".ll")), m)

    def test_unknown_module_is_an_error(self):
        out = tempfile.mkdtemp()
        r = subprocess.run([sys.executable, "-I", GEN, "--module", "NoSuchModule", INVENTORY, out],
                           capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("NoSuchModule", r.stderr)
        self.assertEqual(os.listdir(out), [])

    def test_witness_forwarder_extends_the_char_argument(self):
        text = read(os.path.join(run_gen("--module", "WitnessGeneration"), "WitnessGeneration.ll"))
        self.assertIn("declare void @__m2c_rt_witness_generate_aux_files(ptr, i8 signext)", text)
        self.assertIn("define void @generate_aux_files(ptr %a0, i8 signext %a1)", text)
        self.assertIn("tail call void @__m2c_rt_witness_generate_aux_files(ptr %a0, i8 signext %a1)", text)

    def test_overflow_module_forwards_every_c_function_to_the_core(self):
        """AnalysisModeOverflow.bc (Task 2.3): the C functions with a consumer
        outside the module, each a forwarder to __m2c_rt_overflow_<name>;
        divisionByZeroError and unknown_not_supported stay private (SD-22)."""
        text = read(os.path.join(run_gen("--module", "AnalysisModeOverflow"), "AnalysisModeOverflow.ll"))
        want = {r["symbol"] for r in inventory_rows()
                if "AnalysisModeOverflow.bc" in r["module"].split("+") and r["kind"] == "func"
                and r["referenced_by"] != "-"}
        self.assertEqual(len(want), 13)
        self.assertEqual(defined(text), want)
        self.assertNotIn("divisionByZeroError", text)
        self.assertNotIn("unknown_not_supported", text)
        for sym in want:
            self.assertEqual(gen_ll.IMPLEMENTED[("AnalysisModeOverflow", sym)], f"__m2c_rt_overflow_{sym}")
            self.assertRegex(text, rf"tail call [^@]*@__m2c_rt_overflow_{sym}\(", sym)
        self.assertIn("declare signext i8 @__m2c_rt_overflow_analysis_is_program_correct()\n", text)
        self.assertIn("define signext i8 @analysis_is_program_correct() {\n"
                      "  %r = tail call signext i8 @__m2c_rt_overflow_analysis_is_program_correct()\n"
                      "  ret i8 %r\n}\n", text)
        self.assertIn("define void @map2check_binop_add(i64 %a0, i64 %a1, i32 %a2, i32 %a3, i32 %a4, ptr %a5)",
                      text)

    def test_other_modes_keep_their_analysis_stubs(self):
        out = run_gen()
        for m in ("AnalysisModeAssert", "AnalysisModeNone", "AnalysisModeMemtrack", "AnalysisModeMemcleanup"):
            text = read(os.path.join(out, m + ".ll"))
            self.assertNotIn("__m2c_rt_overflow", text, m)
            self.assertIn("define signext i8 @analysis_is_program_correct() {\n  ret i8 1\n}", text, m)

    def test_every_forwarder_target_is_a_rust_core_export(self):
        src = read(FFI_RS)
        exported = set(re.findall(r'#\[no_mangle\]\s*(?:#\[[^\]]*\]\s*)*pub (?:unsafe )?extern "C" fn (\w+)\(',
                                  src))
        for (module, sym), target in sorted(gen_ll.IMPLEMENTED.items()):
            self.assertIn(target, exported, f"{module}.{sym} -> {target}")


if __name__ == "__main__":
    unittest.main()
