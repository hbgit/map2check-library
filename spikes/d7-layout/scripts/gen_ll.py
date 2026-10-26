#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 spike (Task 1.1): writes the LLVM IR (.ll) of the 20 modules that are
not the Rust core, for one layout strategy.

Usage: gen_ll.py <strategy> <inventory.tsv> <out-dir>
  strategy  fwd   (A refined) every module defines exactly the external
                  functions its C namesake defines, as forwarders to the
                  core's __m2c_rt_* entry points or as stubs; the generator
                  modules carry the KLEE/AFL++ intrinsics, main and
                  setjmp/longjmp.
            alit  (A as in the plan) generator modules only define main and a
                  strong __m2c_sel_generator; the AFL one also defines the
                  reject hook (longjmp). Everything else as in fwd.
            b     (B) generator modules come from Rust no_std crates
                  (gen-b/*); this writes the other 17 modules as in fwd plus
                  b-afl-main.ll (main + setjmp/longjmp + AFL globals) that the
                  build links into the B AFL module.

The output is one <Module>.ll per module (Map2CheckFunctions-glue.ll is the
part of Map2CheckFunctions.bc that is not Rust). Memory-safety entry points
are stubs in this prototype (IMPLEMENTED lists what forwards to Rust).
"""
import csv
import os
import sys

HEADER = (
    'target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-'
    'f80:128-n8:16:32:64-S128"\n'
    'target triple = "x86_64-pc-linux-gnu"\n\n'
)

# Canonical C type (inventory.tsv) -> IR type. x86_64 LP64.
CTYPE = {
    "void": "void",
    "char": "i8", "signed char": "i8", "unsigned char": "i8", "_Bool": "i8",
    "short": "i16", "unsigned short": "i16",
    "int": "i32", "unsigned int": "i32",
    "long": "i64", "unsigned long": "i64",
    "long long": "i64", "unsigned long long": "i64",
    "float": "float", "double": "double",
}


def ir_type(c):
    c = c.strip()
    if c.endswith("*"):
        return "ptr"
    for q in ("const ", "volatile "):
        c = c.replace(q, "")
    c = c.strip()
    if c not in CTYPE:
        raise ValueError(f"no IR type for C type '{c}'")
    return CTYPE[c]


def parse_sig(sig):
    """'void (int, const char *)' -> ('void', ['i32', 'ptr'])"""
    sig = sig.split(" | ")[0]
    ret, args = sig.split(" (", 1)
    args = args.rstrip(")").strip()
    if args in ("", "void"):
        return ir_type(ret), []
    return ir_type(ret), [ir_type(a) for a in args.split(", ")]


def load_inventory(path):
    """module -> [(symbol, ret, args)] for the functions a consumer outside
    the defining module reaches (referenced_by is not '-')."""
    mods = {}
    with open(path, newline="") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            if row["kind"] != "func" or row["referenced_by"] == "-":
                continue
            if row["symbol"] == "main":
                continue
            try:
                ret, args = parse_sig(row["canonical_signature"])
            except ValueError:
                continue  # struct by value: runtime-internal C helpers
            for m in row["module"].split("+"):
                mods.setdefault(m[:-3], []).append((row["symbol"], ret, args))
    return mods


# (module, symbol) -> __m2c_rt_* target in the Rust core.
IMPLEMENTED = {
    ("AnalysisModeAssert", "map2check_assert"): "__m2c_rt_assert_map2check_assert",
    ("WitnessGeneration", "generate_aux_files"): "__m2c_rt_witness_generate_aux_files",
    ("WitnessGeneration", "generate_confirmation_file"): "__m2c_rt_witness_generate_confirmation_file",
}
for op in ("add", "sub", "mul", "add_uint", "sub_uint", "mul_uint", "sdiv", "srem"):
    IMPLEMENTED[("AnalysisModeOverflow", f"map2check_binop_{op}")] = (
        f"__m2c_rt_overflow_map2check_binop_{op}")
IMPLEMENTED[("AnalysisModeOverflow", "overflowError")] = "__m2c_rt_overflow_overflowError"

# Modules whose symbols are all runtime-internal C helpers (container rows by
# value, log files): the Rust core keeps that logic private, so the module is
# empty in every strategy. See d7-layout.md, decision point 2.
EMPTY = ["TrackBBLog", "NonDetLog", "PropertyGenerator", "ContainerRealloc",
         "ContainerBTree", "BTree", "AllocationLog", "ListLog", "HeapLog"]
GENERATORS = ["NonDetGeneratorNone", "NonDetGeneratorKlee", "NonDetGeneratorAFL"]


def zero(t):
    return {"void": None, "ptr": "null", "float": "0.0", "double": "0.0"}.get(t, "0")


def define(sym, ret, args, body):
    params = ", ".join(f"{t} %a{i}" for i, t in enumerate(args))
    return f"define {ret} @{sym}({params}) {{\n{body}}}\n\n"


def forwarder(sym, ret, args, target):
    call_args = ", ".join(f"{t} %a{i}" for i, t in enumerate(args))
    decl = f"declare {ret} @{target}({', '.join(args)})\n"
    if ret == "void":
        body = f"  tail call void @{target}({call_args})\n  ret void\n"
    else:
        body = f"  %r = tail call {ret} @{target}({call_args})\n  ret {ret} %r\n"
    return decl + define(sym, ret, args, body)


def stub(sym, ret, args):
    if sym == "analysis_is_program_correct":
        return define(sym, ret, args, f"  ret {ret} 1\n")
    if ret == "void":
        return define(sym, ret, args, "  ret void\n")
    return define(sym, ret, args, f"  ret {ret} {zero(ret)}\n")


def plain_module(name, syms):
    out = [HEADER, f"; {name}: forwarders to the Rust core (Map2CheckFunctions.bc) and stubs.\n\n"]
    for sym, ret, args in syms:
        target = IMPLEMENTED.get((name, sym))
        out.append(forwarder(sym, ret, args, target) if target else stub(sym, ret, args))
    return "".join(out)


GLUE = HEADER + """; Map2CheckFunctions-glue: the part of Map2CheckFunctions.bc that is not
; Rust. The assume entry points call nondet_assume straight from the
; instrumented program's frame, so the AFL++ generator's longjmp never crosses
; a Rust frame.
declare void @nondet_assume(i32)

define void @map2check_assume(i32 %e) {
  tail call void @nondet_assume(i32 %e)
  ret void
}

define void @map2check_crab_assume(i8 %e) {
  %x = sext i8 %e to i32
  tail call void @nondet_assume(i32 %x)
  ret void
}

define void @map2check_assume_loop(i8 %e) {
  %x = sext i8 %e to i32
  tail call void @nondet_assume(i32 %x)
  ret void
}
"""

# ----------------------------------------------------------------- generators

# C name suffix -> (IR return type, sizeof)
NONDET_TYPES = {
    "char": ("i8", 1), "pointer": ("ptr", 8), "ushort": ("i16", 2),
    "short": ("i16", 2), "long": ("i64", 8), "ulong": ("i64", 8),
    "bool": ("i32", 4), "uchar": ("i8", 1), "size_t": ("i64", 8),
    "loff_t": ("i64", 8), "sector_t": ("i64", 8), "double": ("double", 8),
    "int": ("i32", 4), "uint": ("i32", 4), "unsigned": ("i32", 4),
    "float": ("float", 4), "longlong": ("i64", 8), "ulonglong": ("i64", 8),
    "u8": ("i8", 1), "u16": ("i16", 2), "u32": ("i32", 4),
}
# NonDetGeneratorNone.c defines only these.
NONE_TYPES = ["int", "uint", "char", "ushort", "short", "double", "pointer",
              "long", "float", "longlong", "ulonglong", "u8", "u16", "u32"]


def cstring(name, text):
    data = text.encode() + b"\0"
    esc = "".join(chr(b) if 32 <= b < 127 and b not in (34, 92) else f"\\{b:02X}" for b in data)
    return f'@{name} = private unnamed_addr constant [{len(data)} x i8] c"{esc}"\n'


LOG_BYTES = """declare void @map2check_nondet_memory_byte(i32, i32, i32, ptr)

define internal void @m2c_log_bytes(ptr %p, i64 %n) {
entry:
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %i1, %body ]
  %c = icmp ult i64 %i, %n
  br i1 %c, label %body, label %done
body:
  %q = getelementptr i8, ptr %p, i64 %i
  %b = load i8, ptr %q
  %v = zext i8 %b to i32
  call void @map2check_nondet_memory_byte(i32 0, i32 0, i32 %v, ptr @.memname)
  %i1 = add i64 %i, 1
  br label %head
done:
  ret void
}

"""

PCHAR = """declare ptr @malloc(i64)

define ptr @map2check_non_det_pchar() {
entry:
  %len0 = call i32 @map2check_non_det_unsigned()
  %z = icmp eq i32 %len0, 0
  br i1 %z, label %null, label %go
null:
  ret ptr null
go:
  %big = icmp ugt i32 %len0, 4096
  %len = select i1 %big, i32 4096, i32 %len0
  %n = zext i32 %len to i64
  %s = call ptr @malloc(i64 %n)
  %isnull = icmp eq ptr %s, null
  br i1 %isnull, label %null, label %head
head:
  %i = phi i32 [ 0, %go ], [ %i1, %body ]
  %last = sub i32 %len, 1
  %c = icmp ult i32 %i, %last
  br i1 %c, label %body, label %done
body:
  %ch = call i8 @map2check_non_det_char()
  %ix = zext i32 %i to i64
  %q = getelementptr i8, ptr %s, i64 %ix
  store i8 %ch, ptr %q
  %i1 = add i32 %i, 1
  br label %head
done:
  %ix2 = zext i32 %i to i64
  %q2 = getelementptr i8, ptr %s, i64 %ix2
  store i8 0, ptr %q2
  ret ptr %s
}

"""


def gen_none(sel=None):
    out = [HEADER, "; NonDetGeneratorNone: constants, as NonDetGeneratorNone.c.\n\n"]
    if sel is not None:
        out.append(f"@__m2c_sel_generator = global i32 {sel}\n\n")
    out.append("declare i32 @__map2check_main__()\n\n")
    out.append(define("main", "i32", [], "  %r = call i32 @__map2check_main__()\n  ret i32 0\n"))
    if sel is not None:
        return "".join(out)
    for t in NONE_TYPES:
        ty, _ = NONDET_TYPES[t]
        out.append(define(f"map2check_non_det_{t}", ty, [], f"  ret {ty} {zero(ty)}\n"))
    out.append("declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)\n")
    out.append(define("map2check_non_det_memory", "void", ["ptr", "i64"],
                      "  call void @llvm.memset.p0.i64(ptr %a0, i8 0, i64 %a1, i1 false)\n  ret void\n"))
    for f in ("nondet_init", "nondet_destroy", "nondet_generate_aux_witness_files"):
        out.append(define(f, "void", [], "  ret void\n"))
    out.append(define("nondet_assume", "void", ["i32"], "  ret void\n"))
    return "".join(out)


KLEE_AUX = """declare i32 @__m2c_rt_nondet_log_len()
declare ptr @__m2c_rt_nondet_log_value(i32)
declare void @__m2c_rt_nondet_log_to_file()
declare i64 @klee_get_value_i64(i64)
declare void @klee_assume(i32)

; Concretize every logged value before writing klee_log.csv, as
; NonDetGeneratorKlee.c does (at most 1024 rows).
define void @nondet_generate_aux_witness_files() {
entry:
  %n = call i32 @__m2c_rt_nondet_log_len()
  %big = icmp ugt i32 %n, 1024
  br i1 %big, label %out, label %head
head:
  %i = phi i32 [ 0, %entry ], [ %i1, %body ]
  %c = icmp ult i32 %i, %n
  br i1 %c, label %body, label %write
body:
  %p = call ptr @__m2c_rt_nondet_log_value(i32 %i)
  %v = load i64, ptr %p
  %k = call i64 @klee_get_value_i64(i64 %v)
  %eq = icmp eq i64 %v, %k
  %e = zext i1 %eq to i32
  call void @klee_assume(i32 %e)
  store i64 %k, ptr %p
  %i1 = add i32 %i, 1
  br label %head
write:
  call void @__m2c_rt_nondet_log_to_file()
  br label %out
out:
  ret void
}

"""


def gen_klee(sel=None):
    out = [HEADER, "; NonDetGeneratorKlee: KLEE intrinsics, as NonDetGeneratorKlee.c.\n\n"]
    if sel is not None:
        out.append(f"@__m2c_sel_generator = global i32 {sel}\n\n")
    out.append("declare i32 @__map2check_main__(i32, ptr)\n\n")
    out.append(define("main", "i32", ["i32", "ptr"],
                      "  %r = call i32 @__map2check_main__(i32 %a0, ptr %a1)\n  ret i32 %r\n"))
    if sel is not None:
        return "".join(out)
    out.append("declare void @klee_make_symbolic(ptr, i64, ptr)\ndeclare void @_exit(i32)\n")
    out.append("declare void @nondet_log_init()\ndeclare void @nondet_log_destroy()\n")
    out.append("declare void @free(ptr)\ndeclare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)\n")
    out.append(cstring(".memname", "__VERIFIER_nondet_memory"))
    out.append(cstring(".pruned", "map2check_pruned"))
    out.append(cstring(".memobj", "non_det_memory"))
    for t, (ty, size) in NONDET_TYPES.items():
        out.append(cstring(f".n.{t}", f"non_det_{t}"))
    out.append("\n")
    for t, (ty, size) in NONDET_TYPES.items():
        out.append(define(f"map2check_non_det_{t}", ty, [],
                          f"  %p = alloca {ty}\n"
                          f"  call void @klee_make_symbolic(ptr %p, i64 {size}, ptr @.n.{t})\n"
                          f"  %v = load {ty}, ptr %p\n  ret {ty} %v\n"))
    out.append(PCHAR)
    out.append(LOG_BYTES)
    out.append(define("map2check_non_det_memory", "void", ["ptr", "i64"],
                      "  %z = icmp eq i64 %a1, 0\n  br i1 %z, label %out, label %go\n"
                      "go:\n  %b = call ptr @malloc(i64 %a1)\n  %bn = icmp eq ptr %b, null\n"
                      "  br i1 %bn, label %out, label %sym\nsym:\n"
                      "  call void @klee_make_symbolic(ptr %b, i64 %a1, ptr @.memobj)\n"
                      "  call void @llvm.memcpy.p0.p0.i64(ptr %a0, ptr %b, i64 %a1, i1 false)\n"
                      "  call void @m2c_log_bytes(ptr %b, i64 %a1)\n"
                      "  call void @free(ptr %b)\n  br label %out\nout:\n  ret void\n"))
    out.append(define("nondet_assume", "void", ["i32"],
                      "  %z = icmp eq i32 %a0, 0\n  br i1 %z, label %prune, label %ok\n"
                      "prune:\n  %p = alloca i8\n"
                      "  call void @klee_make_symbolic(ptr %p, i64 1, ptr @.pruned)\n"
                      "  call void @_exit(i32 0)\n  unreachable\nok:\n  ret void\n"))
    out.append(define("nondet_init", "void", [], "  call void @nondet_log_init()\n  ret void\n"))
    out.append(define("nondet_destroy", "void", [], "  call void @nondet_log_destroy()\n  ret void\n"))
    out.append(KLEE_AUX)
    return "".join(out)


# main + setjmp/longjmp + the __AFL_FUZZ_INIT/__AFL_LOOP expansions of
# afl-cc 4.40c, as NonDetGeneratorAFL.c has them. `data`, `size` and `index`
# are the reader's globals: in fwd/alit they are named here or in the core,
# in b they are the Rust crate's statics.
AFL_MAIN = """@__afl_sharedmem_fuzzing = global i32 1
@__afl_fuzz_len = external global ptr
@__afl_fuzz_ptr = external global ptr
@__afl_connected = external global i32
@__afl_fuzz_alt = global [1048576 x i8] zeroinitializer
@__afl_fuzz_alt_ptr = global ptr @__afl_fuzz_alt
@.sig = private constant [23 x i8] c"##SIG_AFL_PERSISTENT##\\00"
@m2c_afl_sig_ref = internal global ptr null
@llvm.used = appending global [1 x ptr] [ptr @m2c_afl_sig_ref], section "llvm.metadata"
@map2check_reject_env = internal global [25 x i64] zeroinitializer, align 16

declare i32 @__afl_persistent_loop(i32)
declare i32 @_setjmp(ptr) returns_twice
declare void @longjmp(ptr, i32) noreturn
declare i64 @read(i32, ptr, i64)
declare i32 @__map2check_main__(i32, ptr)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %loop
loop:
  store volatile ptr @.sig, ptr @m2c_afl_sig_ref
  %conn = load i32, ptr @__afl_connected
  %nz = icmp ne i32 %conn, 0
  %cnt = select i1 %nz, i32 10000, i32 1
  %r = call i32 @__afl_persistent_loop(i32 %cnt)
  %go = icmp ne i32 %r, 0
  br i1 %go, label %body, label %exit
body:
  %sj = call i32 @_setjmp(ptr @map2check_reject_env) returns_twice
  %first = icmp eq i32 %sj, 0
  br i1 %first, label %run, label %loop
run:
  %fp = load ptr, ptr @__afl_fuzz_ptr
  %has = icmp ne ptr %fp, null
  br i1 %has, label %shm, label %stdin
shm:
  %lp = load ptr, ptr @__afl_fuzz_len
  %len = load i32, ptr %lp
  br label %set
stdin:
  %alt = load ptr, ptr @__afl_fuzz_alt_ptr
  %rd = call i64 @read(i32 0, ptr %alt, i64 1048576)
  %rd32 = trunc i64 %rd to i32
  %lp2 = load ptr, ptr @__afl_fuzz_len
  store i32 %rd32, ptr %lp2
  %bad = icmp eq i32 %rd32, -1
  %len2 = select i1 %bad, i32 0, i32 %rd32
  br label %set
set:
  %buf = phi ptr [ %fp, %shm ], [ %alt, %stdin ]
  %l = phi i32 [ %len, %shm ], [ %len2, %stdin ]
  store ptr %buf, ptr @map2check_afl_data
  %l64 = zext i32 %l to i64
  store i64 %l64, ptr @map2check_afl_size
  store i64 0, ptr @map2check_afl_index
  %m = call i32 @__map2check_main__(i32 0, ptr null)
  br label %loop
exit:
  ret i32 0
}

"""

AFL_READER = """@map2check_afl_data = global ptr null
@map2check_afl_size = global i64 0
@map2check_afl_index = internal global i64 0

define i8 @get_next_input_from_afl() {
entry:
  %i = load i64, ptr @map2check_afl_index
  %n = load i64, ptr @map2check_afl_size
  %in = icmp ult i64 %i, %n
  br i1 %in, label %read, label %zero
read:
  %d = load ptr, ptr @map2check_afl_data
  %q = getelementptr i8, ptr %d, i64 %i
  %b = load i8, ptr %q
  %i1 = add i64 %i, 1
  store i64 %i1, ptr @map2check_afl_index
  ret i8 %b
zero:
  ret i8 0
}

define internal void @m2c_afl_get_bytes(ptr %out, i64 %n) {
entry:
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %i1, %body ]
  %c = icmp ult i64 %i, %n
  br i1 %c, label %body, label %done
body:
  %b = call i8 @get_next_input_from_afl()
  %q = getelementptr i8, ptr %out, i64 %i
  store i8 %b, ptr %q
  %i1 = add i64 %i, 1
  br label %head
done:
  ret void
}

"""

AFL_REJECT = """define void @nondet_cancel() {
  call void @longjmp(ptr @map2check_reject_env, i32 1)
  unreachable
}

"""


def gen_afl(sel=None):
    out = [HEADER, "; NonDetGeneratorAFL: AFL++ persistent mode, as NonDetGeneratorAFL.c.\n\n"]
    if sel is not None:
        # A as in the plan: the reader lives in the core; main fills its globals.
        out.append(f"@__m2c_sel_generator = global i32 {sel}\n")
        out.append("@map2check_afl_data = external global ptr\n@map2check_afl_size = external global i64\n"
                   "@map2check_afl_index = external global i64\n")
        out.append(AFL_MAIN)
        out.append(define("__m2c_afl_reject", "void", [],
                          "  call void @longjmp(ptr @map2check_reject_env, i32 1)\n  unreachable\n"))
        return "".join(out)
    out.append(AFL_MAIN)
    out.append(AFL_READER)
    out.append(AFL_REJECT)
    out.append("declare void @nondet_log_init()\ndeclare void @nondet_log_destroy()\n"
               "declare void @__m2c_rt_nondet_log_to_file()\n")
    out.append(cstring(".memname", "__VERIFIER_nondet_memory"))
    out.append("\n")
    for t, (ty, size) in NONDET_TYPES.items():
        out.append(define(f"map2check_non_det_{t}", ty, [],
                          f"  %p = alloca {ty}\n  call void @m2c_afl_get_bytes(ptr %p, i64 {size})\n"
                          f"  %v = load {ty}, ptr %p\n  ret {ty} %v\n"))
    out.append(PCHAR)
    out.append(LOG_BYTES)
    out.append(define("map2check_non_det_memory", "void", ["ptr", "i64"],
                      "  call void @m2c_afl_get_bytes(ptr %a0, i64 %a1)\n"
                      "  call void @m2c_log_bytes(ptr %a0, i64 %a1)\n  ret void\n"))
    out.append(define("nondet_assume", "void", ["i32"],
                      "  %z = icmp eq i32 %a0, 0\n  br i1 %z, label %rej, label %ok\n"
                      "rej:\n  call void @longjmp(ptr @map2check_reject_env, i32 1)\n  unreachable\n"
                      "ok:\n  ret void\n"))
    out.append(define("nondet_init", "void", [], "  call void @nondet_log_init()\n  ret void\n"))
    out.append(define("nondet_destroy", "void", [], "  call void @nondet_log_destroy()\n  ret void\n"))
    out.append(define("nondet_generate_aux_witness_files", "void", [],
                      "  call void @__m2c_rt_nondet_log_to_file()\n  ret void\n"))
    return "".join(out)


B_AFL_MAIN = HEADER + """; B: main, setjmp/longjmp and the AFL++ globals in IR, linked into the
; Rust no_std AFL generator (gen-b/afl). nondet_assume is here too, so the
; longjmp never crosses a Rust frame.
@map2check_afl_data = external global ptr
@map2check_afl_size = external global i64
@map2check_afl_index = external global i64
""" + AFL_MAIN + AFL_REJECT + """define void @nondet_assume(i32 %e) {
  %z = icmp eq i32 %e, 0
  br i1 %z, label %rej, label %ok
rej:
  call void @longjmp(ptr @map2check_reject_env, i32 1)
  unreachable
ok:
  ret void
}
"""


def main():
    strategy, inventory, out_dir = sys.argv[1:4]
    if strategy not in ("fwd", "alit", "b"):
        sys.exit(f"unknown strategy {strategy}")
    mods = load_inventory(inventory)
    os.makedirs(out_dir, exist_ok=True)

    def write(name, text):
        with open(os.path.join(out_dir, name + ".ll"), "w") as f:
            f.write(text)

    write("Map2CheckFunctions-glue", GLUE)
    for m in EMPTY:
        write(m, HEADER + f"; {m}: empty. Its C functions are runtime-internal helpers;\n"
                          "; the Rust core keeps that logic private.\n")
    for m in ["AnalysisModeMemtrack", "AnalysisModeMemcleanup", "AnalysisModeOverflow",
              "AnalysisModeAssert", "AnalysisModeNone", "WasmRuntimeStubs",
              "WitnessGeneration", "WitnessGenerationNone"]:
        write(m, plain_module(m, mods.get(m, [])))
    if strategy == "fwd":
        write("NonDetGeneratorNone", gen_none())
        write("NonDetGeneratorKlee", gen_klee())
        write("NonDetGeneratorAFL", gen_afl())
    elif strategy == "alit":
        write("NonDetGeneratorNone", gen_none(0))
        write("NonDetGeneratorKlee", gen_klee(1))
        write("NonDetGeneratorAFL", gen_afl(2))
    else:
        write("b-afl-main", B_AFL_MAIN)


if __name__ == "__main__":
    main()
