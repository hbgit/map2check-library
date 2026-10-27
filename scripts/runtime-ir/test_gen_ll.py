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
HEADER_H = os.path.join(ROOT, "include", "map2check.h")
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
        self.assertEqual(text, "define signext i8 @analysis_is_program_correct() { ; m2c-stub\n  ret i8 1\n}\n\n")

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

    def test_assert_module_forwards_to_the_core_and_verifier_assert_is_empty(self):
        """AnalysisModeAssert.bc (Task 2.4): map2check_assert and analysis_*
        forward to __m2c_rt_assert_*; __VERIFIER_assert is an unmarked empty
        function, as AnalysisModeAssert.c:25-27 ("DO NOTHING")."""
        text = read(os.path.join(run_gen("--module", "AnalysisModeAssert"), "AnalysisModeAssert.ll"))
        want = {r["symbol"] for r in inventory_rows()
                if "AnalysisModeAssert.bc" in r["module"].split("+") and r["kind"] == "func"
                and r["referenced_by"] != "-"}
        self.assertEqual(want, {"__VERIFIER_assert", "map2check_assert", "analysis_init", "analysis_destroy",
                                "analysis_is_program_correct", "analysis_generate_aux_witness_files"})
        self.assertEqual(defined(text), want)
        for sym in want - {"__VERIFIER_assert"}:
            self.assertEqual(gen_ll.IMPLEMENTED[("AnalysisModeAssert", sym)], f"__m2c_rt_assert_{sym}")
            self.assertRegex(text, rf"tail call [^@]*@__m2c_rt_assert_{sym}\(", sym)
        self.assertIn("define void @__VERIFIER_assert(i32 %a0) {\n  ret void\n}\n", text)
        self.assertNotIn("__m2c_rt_assert___VERIFIER_assert", text)
        self.assertNotIn("m2c-stub", text)
        self.assertIn("declare void @__m2c_rt_assert_map2check_assert(i32, i32, ptr)\n", text)
        self.assertIn("define void @map2check_assert(i32 %a0, i32 %a1, ptr %a2) {\n"
                      "  tail call void @__m2c_rt_assert_map2check_assert(i32 %a0, i32 %a1, ptr %a2)\n"
                      "  ret void\n}\n", text)

    def test_none_module_forwards_analysis_functions_and_selects_the_mode(self):
        """AnalysisModeNone.bc (Task 2.4): the four analysis_* functions, each
        a forwarder to __m2c_rt_none_<name>; analysis_init selects the mode."""
        text = read(os.path.join(run_gen("--module", "AnalysisModeNone"), "AnalysisModeNone.ll"))
        want = {"analysis_init", "analysis_destroy", "analysis_is_program_correct",
                "analysis_generate_aux_witness_files"}
        self.assertEqual(defined(text), want)
        for sym in want:
            self.assertEqual(gen_ll.IMPLEMENTED[("AnalysisModeNone", sym)], f"__m2c_rt_none_{sym}")
            self.assertRegex(text, rf"tail call [^@]*@__m2c_rt_none_{sym}\(", sym)
        self.assertNotIn("m2c-stub", text)

    def test_memtrack_module_forwards_every_c_function_to_the_core(self):
        """AnalysisModeMemtrack.bc (Task 2.5): the 12 memory map2check_* the
        pass calls, map2check_wasm_{malloc,free,check_access} and analysis_*,
        each a forwarder to __m2c_rt_memtrack_<name> with the signature of
        the C definition (inventory canonical_signature). The c-only names
        (update_reference_list_log, the logs, ERROR_DEREF) are not defined."""
        text = read(os.path.join(run_gen("--module", "AnalysisModeMemtrack"), "AnalysisModeMemtrack.ll"))
        want = {r["symbol"] for r in inventory_rows()
                if "AnalysisModeMemtrack.bc" in r["module"].split("+") and r["kind"] == "func"
                and r["referenced_by"] != "-"}
        memory = {"map2check_add_store_pointer", "map2check_alloca", "map2check_calloc",
                  "map2check_check_cstring", "map2check_check_deref", "map2check_free",
                  "map2check_free_resolved_address", "map2check_function", "map2check_load",
                  "map2check_malloc", "map2check_non_static_alloca", "map2check_posix"}
        wasm = {"map2check_wasm_malloc", "map2check_wasm_free", "map2check_wasm_check_access"}
        analysis = {"analysis_init", "analysis_destroy", "analysis_is_program_correct",
                    "analysis_generate_aux_witness_files"}
        self.assertEqual(want, memory | wasm | analysis)
        self.assertEqual(defined(text), want)
        for sym in want:
            self.assertEqual(gen_ll.IMPLEMENTED[("AnalysisModeMemtrack", sym)], f"__m2c_rt_memtrack_{sym}")
            self.assertRegex(text, rf"tail call [^@]*@__m2c_rt_memtrack_{sym}\(", sym)
        self.assertNotIn("m2c-stub", text)
        for c_only in ("update_reference_list_log", "@heap_log", "@list_log", "@allocation_log", "ERROR_DEREF"):
            self.assertNotIn(c_only, text)
        # The C definitions, not the pass prototypes (MemoryTrackPass.cpp:885-955
        # declares (ptr, i64), (ptr, i64, ptr, i1), (i64, ptr) and (i64, i64)).
        for line in ("define void @map2check_load(ptr %a0, i32 %a1) {",
                     "define void @map2check_free_resolved_address(ptr %a0, i32 %a1, ptr %a2, i16 signext %a3) {",
                     "define void @map2check_check_deref(i32 %a0, ptr %a1) {",
                     "define void @map2check_wasm_free(i64 %a0, i32 %a1) {",
                     "define void @map2check_alloca(ptr %a0, ptr %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5) {",
                     "define signext i8 @analysis_is_program_correct() {"):
            self.assertIn(line, text)

    def test_memcleanup_module_forwards_every_c_function_to_the_core(self):
        """AnalysisModeMemcleanup.bc (Task 2.6): the 12 memory map2check_* and
        analysis_*, each a forwarder to __m2c_rt_memcleanup_<name> with the
        signature of the C definition. Unlike memtrack it has no
        map2check_wasm_*, and the c-only names are not defined."""
        text = read(os.path.join(run_gen("--module", "AnalysisModeMemcleanup"), "AnalysisModeMemcleanup.ll"))
        want = {r["symbol"] for r in inventory_rows()
                if "AnalysisModeMemcleanup.bc" in r["module"].split("+") and r["kind"] == "func"
                and r["referenced_by"] != "-"}
        memory = {"map2check_add_store_pointer", "map2check_alloca", "map2check_calloc",
                  "map2check_check_cstring", "map2check_check_deref", "map2check_free",
                  "map2check_free_resolved_address", "map2check_function", "map2check_load",
                  "map2check_malloc", "map2check_non_static_alloca", "map2check_posix"}
        analysis = {"analysis_init", "analysis_destroy", "analysis_is_program_correct",
                    "analysis_generate_aux_witness_files"}
        self.assertEqual(want, memory | analysis)
        self.assertEqual(defined(text), want)
        self.assertNotIn("wasm", text)
        for sym in want:
            self.assertEqual(gen_ll.IMPLEMENTED[("AnalysisModeMemcleanup", sym)], f"__m2c_rt_memcleanup_{sym}")
            self.assertRegex(text, rf"tail call [^@]*@__m2c_rt_memcleanup_{sym}\(", sym)
        self.assertNotIn("m2c-stub", text)
        self.assertNotIn("__m2c_rt_memtrack", text)
        for c_only in ("update_reference_list_log", "@heap_log", "@list_log", "@allocation_log", "ERROR_DEREF"):
            self.assertNotIn(c_only, text)
        for line in ("define void @map2check_load(ptr %a0, i32 %a1) {",
                     "define void @map2check_free_resolved_address(ptr %a0, i32 %a1, ptr %a2, i16 signext %a3) {",
                     "define signext i8 @analysis_is_program_correct() {"):
            self.assertIn(line, text)

    def test_container_and_log_modules_are_empty_without_stub_marks(self):
        """D3: one Rust container serves the Array (ContainerRealloc.bc) and
        --btree (ContainerBTree.bc + BTree.bc) builds, and the log modules
        (AllocationLog, ListLog, HeapLog) are C-only helpers (SD-22): every
        one is an empty IR module, so both module sets link the same core."""
        out = run_gen()
        bodies = {}
        for m in ("ContainerRealloc", "ContainerBTree", "BTree", "AllocationLog", "ListLog", "HeapLog"):
            self.assertIn(m, gen_ll.EMPTY)
            text = read(os.path.join(out, m + ".ll"))
            self.assertEqual(defined(text), set(), m)
            self.assertNotIn("m2c-stub", text, m)
            self.assertNotRegex(text, r"(?m)^(declare|@)", m)
            bodies[m] = text.replace(m, "<M>")
        self.assertEqual(bodies["ContainerRealloc"], bodies["ContainerBTree"])
        self.assertEqual(bodies["ContainerRealloc"], bodies["BTree"])

    def test_stubs_are_marked_and_forwarders_are_not(self):
        """runtime-abi-coverage.sh must not count a stub as delivered: every
        define that does not do the C function's work carries `; m2c-stub`."""
        out = run_gen()
        for name in os.listdir(out):
            for line in read(os.path.join(out, name)).splitlines():
                if not line.startswith("define "):
                    continue
                sym = line.split("@", 1)[1].split("(", 1)[0]
                module = name[:-3]
                if module in gen_ll.PLAIN:
                    real = (module, sym) in gen_ll.IMPLEMENTED or (module, sym) in gen_ll.C_EMPTY
                    self.assertEqual(line.endswith("; m2c-stub"), not real, f"{module}.{sym}")
                else:
                    self.assertNotIn("m2c-stub", line, f"{module}.{sym}")
        # Still stubs: the wasm module (Task 2.9). The generator modules have none.
        text = read(os.path.join(out, "WasmRuntimeStubs.ll"))
        self.assertIn("{ ; m2c-stub", text)
        # The empty C bodies: WitnessGenerationNone.c, AnalysisModeAssert.c:25-27
        # (__VERIFIER_assert); all "DO NOTHING".
        self.assertEqual(gen_ll.C_EMPTY, {("WitnessGenerationNone", "generate_aux_files"),
                                          ("WitnessGenerationNone", "generate_confirmation_file"),
                                          ("AnalysisModeAssert", "__VERIFIER_assert")})
        self.assertIn("define void @generate_confirmation_file() {\n  ret void\n}",
                      read(os.path.join(out, "WitnessGenerationNone.ll")))

    @unittest.skipUnless(shutil.which("clang"), "clang not installed")
    def test_every_core_entry_point_referenced_matches_the_header(self):
        """Every @__m2c_rt_* that any generated module declares or calls is a
        prototype of include/map2check.h, and its IR declaration and every call
        have the types and ext attributes clang gives that prototype (D7
        finding 4: forwarders checked against the header)."""
        out = run_gen()
        header = read(HEADER_H)
        protos = set(re.findall(r"\b(__m2c_rt_\w+)\(", header))
        decls, calls = {}, []
        for name in sorted(os.listdir(out)):
            for line in read(os.path.join(out, name)).splitlines():
                refs = re.findall(r"@(__m2c_rt_\w+)\(", line)
                if not refs:
                    continue
                if line.startswith("declare "):
                    sym, ret, args = abi_of(line)
                    decls.setdefault(sym, set()).add((name, ret, tuple(args)))
                elif re.search(r"\bcall\b", line):
                    sym, ret, args = abi_of(line)
                    calls.append((name, sym, ret, tuple(args)))
                else:
                    self.fail(f"{name}: unexpected reference: {line}")
        referenced = set(decls) | {c[1] for c in calls}
        self.assertTrue(referenced, "no __m2c_rt_* reference at all")
        self.assertEqual(sorted(referenced - protos), [], "not exported by the core (not in map2check.h)")
        tmp = tempfile.mkdtemp()
        with open(os.path.join(tmp, "refs.c"), "w") as f:
            f.write('#include "map2check.h"\n')
            f.write("void *m2c_refs[] = {\n" + "".join(f"  (void *)&{s},\n" for s in sorted(referenced)) + "};\n")
        ll = subprocess.run(["clang", "-O0", "-w", "-S", "-emit-llvm", "--target=x86_64-pc-linux-gnu",
                             "-I", os.path.dirname(HEADER_H), os.path.join(tmp, "refs.c"), "-o", "-"],
                            check=True, capture_output=True, text=True).stdout
        want = {}
        for line in ll.splitlines():
            if line.startswith("declare ") and "@__m2c_rt_" in line:
                sym, ret, args = abi_of(line)
                want[sym] = (ret, tuple(args))
        self.assertEqual(set(want), referenced)
        for sym, seen in sorted(decls.items()):
            for module, ret, args in seen:
                self.assertEqual((ret, args), want[sym], f"{module}: declare {sym}")
        for module, sym, ret, args in calls:
            self.assertIn(sym, decls, f"{module}: call {sym} without declare")
            self.assertEqual((ret, args), want[sym], f"{module}: call {sym}")

    def test_klee_aux_pins_the_log_through_the_core_hooks(self):
        """nondet_generate_aux_witness_files of NonDetGeneratorKlee.c:33-62:
        nothing above 1024 rows; else each row's 64-bit value goes through
        klee_get_value_i64 + klee_assume and back, then nondet_log_to_file."""
        text = read(os.path.join(run_gen("--module", "NonDetGeneratorKlee"), "NonDetGeneratorKlee.ll"))
        body = text.split("define void @nondet_generate_aux_witness_files() {", 1)[1].split("\n}\n", 1)[0]
        for needle in ("call i32 @__m2c_rt_nondet_log_len()", "icmp ugt i32 %n, 1024",
                       "call i64 @__m2c_rt_nondet_log_get_i64(i32 %i)",
                       "call i64 @klee_get_value_i64(i64 %v)", "call void @klee_assume(i32 %e)",
                       "call void @__m2c_rt_nondet_log_set_i64(i32 %i, i64 %k)",
                       "call signext i8 @__m2c_rt_nondet_log_to_file()"):
            self.assertIn(needle, body)
        self.assertNotIn("nondet_log_value", text)

    def test_klee_generator_is_complete_without_stubs(self):
        """NonDetGeneratorKlee.c (Task 2.7): main, the 21 typed generators with
        klee_make_symbolic of a sizeof(type) object named "non_det_<t>",
        pchar, memory, nondet_assume, nondet_init/destroy and the witness
        log; nothing else and no stub."""
        text = read(os.path.join(run_gen("--module", "NonDetGeneratorKlee"), "NonDetGeneratorKlee.ll"))
        self.assertNotIn("m2c-stub", text)
        types = ["int", "char", "pointer", "ushort", "short", "long", "unsigned", "ulong", "bool",
                 "uchar", "size_t", "loff_t", "sector_t", "uint", "double", "float", "longlong",
                 "ulonglong", "u8", "u16", "u32"]
        self.assertEqual(len(types), 21)
        want = {"main", "nondet_init", "nondet_destroy", "nondet_assume",
                "nondet_generate_aux_witness_files", "map2check_non_det_pchar",
                "map2check_non_det_memory", *(f"map2check_non_det_{t}" for t in types)}
        self.assertEqual(defined(text) - {"m2c_log_bytes"}, want)
        sizes = {"char": 1, "uchar": 1, "u8": 1, "short": 2, "ushort": 2, "u16": 2, "int": 4,
                 "unsigned": 4, "uint": 4, "u32": 4, "bool": 4, "float": 4, "long": 8, "ulong": 8,
                 "size_t": 8, "loff_t": 8, "sector_t": 8, "longlong": 8, "ulonglong": 8,
                 "double": 8, "pointer": 8}
        for t in types:
            body = text.split(f"@map2check_non_det_{t}() {{", 1)[1].split("\n}\n", 1)[0]
            self.assertIn(f"call void @klee_make_symbolic(ptr %p, i64 {sizes[t]}, ptr @.n.{t})", body, t)
            self.assertIn(f'@.n.{t} = private unnamed_addr constant [{len(t) + 9} x i8] c"non_det_{t}\\00"',
                          text, t)
        # main(argc, argv) -> __map2check_main__(argc, argv) (NonDetGeneratorKlee.c:18).
        self.assertIn("define i32 @main(i32 %a0, ptr %a1) {\n"
                      "  %r = call i32 @__map2check_main__(i32 %a0, ptr %a1)\n  ret i32 %r\n}", text)
        # nondet_assume: a one-byte "map2check_pruned" object, then _exit(0).
        body = text.split("define void @nondet_assume(i32 %a0) {", 1)[1].split("\n}\n", 1)[0]
        self.assertIn("call void @klee_make_symbolic(ptr %p, i64 1, ptr @.pruned)", body)
        self.assertIn("call void @_exit(i32 0)", body)
        self.assertIn('c"map2check_pruned\\00"', text)
        # nondet_init turns on SD-20's atomic result files, then starts the
        # log (user decision of 2026-10-27: atomic under KLEE only).
        self.assertIn("define void @nondet_init() {\n  call void @__m2c_rt_output_set_atomic(i32 1)\n"
                      "  call void @nondet_log_init()\n  ret void\n}", text)
        self.assertIn("define void @nondet_destroy() {\n  call void @nondet_log_destroy()\n  ret void\n}", text)
        # memory: one fresh "non_det_memory" object of `size` bytes, copied
        # in, logged byte by byte, freed (NonDetGeneratorKlee.c:140-153).
        body = text.split("define void @map2check_non_det_memory(ptr %a0, i64 %a1) {", 1)[1].split("\n}\n", 1)[0]
        for needle in ("call ptr @malloc(i64 %a1)", "call void @klee_make_symbolic(ptr %b, i64 %a1, ptr @.memobj)",
                       "@llvm.memcpy.p0.p0.i64(ptr %a0, ptr %b, i64 %a1", "call void @m2c_log_bytes(ptr %b, i64 %a1)",
                       "call void @free(ptr %b)"):
            self.assertIn(needle, body)

    def test_afl_generator_is_complete_without_stubs(self):
        """NonDetGeneratorAFL.c (Task 2.8): the __AFL_FUZZ_INIT / __AFL_LOOP
        globals, main, the reader and its globals, the 21 typed generators
        reading sizeof(type) bytes, pchar, memory, nondet_cancel /
        nondet_assume (longjmp), nondet_init/destroy and the witness log;
        nothing else and no stub."""
        text = read(os.path.join(run_gen("--module", "NonDetGeneratorAFL"), "NonDetGeneratorAFL.ll"))
        self.assertNotIn("m2c-stub", text)
        sizes = {"char": 1, "uchar": 1, "u8": 1, "short": 2, "ushort": 2, "u16": 2, "int": 4,
                 "unsigned": 4, "uint": 4, "u32": 4, "bool": 4, "float": 4, "long": 8, "ulong": 8,
                 "size_t": 8, "loff_t": 8, "sector_t": 8, "longlong": 8, "ulonglong": 8,
                 "double": 8, "pointer": 8}
        self.assertEqual(len(sizes), 21)
        want = {"main", "get_next_input_from_afl", "nondet_init", "nondet_destroy", "nondet_assume",
                "nondet_cancel", "nondet_generate_aux_witness_files", "map2check_non_det_pchar",
                "map2check_non_det_memory", *(f"map2check_non_det_{t}" for t in sizes)}
        self.assertEqual(defined(text) - {"m2c_log_bytes", "m2c_afl_get_bytes"}, want)
        for t, n in sizes.items():
            body = text.split(f"@map2check_non_det_{t}() {{", 1)[1].split("\n}\n", 1)[0]
            self.assertIn(f"call void @m2c_afl_get_bytes(ptr %p, i64 {n})", body, t)
        # The globals of the expansions and of the reader, with the C's
        # linkage and alignment (clang-16 -O0 of NonDetGeneratorAFL.c).
        for g in ("@__afl_sharedmem_fuzzing = global i32 1, align 4",
                  "@__afl_fuzz_alt = global [1048576 x i8] zeroinitializer, align 16",
                  "@__afl_fuzz_alt_ptr = global ptr @__afl_fuzz_alt, align 8",
                  "@__afl_fuzz_len = external global ptr, align 8",
                  "@__afl_fuzz_ptr = external global ptr, align 8",
                  "@__afl_connected = external global i32, align 4",
                  "@map2check_afl_data = global ptr null, align 8",
                  "@map2check_afl_size = global i64 0, align 8",
                  "@map2check_afl_index = internal global i64 0, align 8",
                  "@map2check_reject_env = internal global [25 x i64] zeroinitializer, align 16",
                  '@.sig = private constant [23 x i8] c"##SIG_AFL_PERSISTENT##\\00"'):
            self.assertIn(g + "\n", text)
        # main: __AFL_LOOP(10000) (1 when not connected), _setjmp, the shared
        # memory test case or stdin, the reader rewound, __map2check_main__(0, NULL).
        body = text.split("define i32 @main(i32 %argc, ptr %argv) {", 1)[1].split("\n}\n", 1)[0]
        for needle in ("store volatile ptr @.sig, ptr @m2c_afl_sig_ref",
                       "%cnt = select i1 %nz, i32 10000, i32 1",
                       "call i32 @__afl_persistent_loop(i32 %cnt)",
                       "call i32 @_setjmp(ptr @map2check_reject_env) #1",
                       "call i64 @read(i32 0, ptr %alt, i64 1048576)",
                       "%len2 = select i1 %bad, i32 0, i32 %rd32",
                       "store i64 0, ptr @map2check_afl_index",
                       "call i32 @__map2check_main__(i32 0, ptr null)"):
            self.assertIn(needle, body)
        self.assertIn("declare i32 @_setjmp(ptr) #1\n", text)
        self.assertIn("declare void @longjmp(ptr, i32) #0\n", text)
        self.assertIn("attributes #0 = { noreturn nounwind }\nattributes #1 = { nounwind returns_twice }\n", text)
        # Past the end of the test case the reader returns 0 (C :61-66).
        body = text.split("define zeroext i8 @get_next_input_from_afl() {", 1)[1].split("\n}\n", 1)[0]
        self.assertIn("zero:\n  ret i8 0", body)
        for f, callee in (("nondet_init", "nondet_log_init"), ("nondet_destroy", "nondet_log_destroy")):
            self.assertIn(f"define void @{f}() {{\n  call void @{callee}()\n  ret void\n}}", text)
        # Plain result files, as the C (SD-20 applies to KLEE only).
        self.assertNotIn("__m2c_rt_output_set_atomic", text)
        # nondet_cancel longjmps back to main; a failed nondet_assume cancels.
        self.assertIn("define void @nondet_cancel() {\n  call void @longjmp(ptr @map2check_reject_env, i32 1)\n"
                      "  unreachable\n}", text)
        self.assertIn("define void @nondet_assume(i32 %a0) {\n  %z = icmp eq i32 %a0, 0\n"
                      "  br i1 %z, label %rej, label %ok\nrej:\n  call void @nondet_cancel()\n  unreachable\n"
                      "ok:\n  ret void\n}", text)
        self.assertEqual(text.count("call void @longjmp("), 1)

    def test_only_the_assume_entry_points_reach_longjmp(self):
        """The longjmp-safety argument of D7 item 5 (Task 2.8): within the IR
        modules, the only functions from which a longjmp is reachable are the
        AFL++ generator's nondet_cancel / nondet_assume and the glue's
        map2check_assume* that call them. None of the functions the Rust core
        calls into the IR (analysis_*, nondet_init/destroy, generate_*) is
        among them, so no Rust frame is ever below a longjmp;
        build-test-runtime-bc.sh checks the core side (it references none of
        these names)."""
        out = run_gen()
        reach = set()
        for name in ALL_MODULES:
            text = read(os.path.join(out, name + ".ll"))
            bodies = {}
            for chunk in text.split("\ndefine ")[1:]:
                head, body = chunk.split("{", 1)
                bodies[head.split("@", 1)[1].split("(", 1)[0]] = body.split("\n}\n", 1)[0]
            jumps = {"longjmp", "nondet_assume", "nondet_cancel"}
            hit = {f for f, b in bodies.items() if any(f"@{j}(" in b for j in jumps)}
            grew = True
            while grew:
                more = {f for f, b in bodies.items() if any(f"@{h}(" in b for h in hit)} - hit
                grew = bool(more)
                hit |= more
            reach |= {f"{name}:{f}" for f in hit}
        self.assertEqual(reach, {
            "NonDetGeneratorAFL:nondet_cancel", "NonDetGeneratorAFL:nondet_assume",
            "Map2CheckFunctions-glue:map2check_assume",
            "Map2CheckFunctions-glue:map2check_crab_assume",
            "Map2CheckFunctions-glue:map2check_assume_loop"})

    def test_klee_pchar_has_no_length_cap_and_afl_keeps_its_own(self):
        """NonDetGeneratorKlee.c:94-109 mallocs the symbolic length as is; only
        NonDetGeneratorAFL.c:128-129 caps it at MAP2CHECK_MAX_FUZZED_STRING."""
        out = run_gen()
        klee = read(os.path.join(out, "NonDetGeneratorKlee.ll"))
        afl = read(os.path.join(out, "NonDetGeneratorAFL.ll"))
        body = klee.split("define ptr @map2check_non_det_pchar() {", 1)[1].split("\n}\n", 1)[0]
        self.assertNotIn("4096", body)
        self.assertIn("call i32 @map2check_non_det_unsigned()", body)
        self.assertIn("call signext i8 @map2check_non_det_char()", body)
        body = afl.split("define ptr @map2check_non_det_pchar() {", 1)[1].split("\n}\n", 1)[0]
        self.assertIn("icmp ugt i32 %len0, 4096", body)

    def test_every_forwarder_target_is_a_rust_core_export(self):
        src = read(FFI_RS)
        exported = set(re.findall(r'#\[no_mangle\]\s*(?:#\[[^\]]*\]\s*)*pub (?:unsafe )?extern "C" fn (\w+)\(',
                                  src))
        for (module, sym), target in sorted(gen_ll.IMPLEMENTED.items()):
            self.assertIn(target, exported, f"{module}.{sym} -> {target}")


if __name__ == "__main__":
    unittest.main()
