#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Writes the LLVM IR (.ll) of the runtime modules that are not the Rust core,
in the A-fwd layout approved in D7 (docs/cutover/d7-layout.md). Promoted from
the D7 spike (spikes/d7-layout/scripts/gen_ll.py), fwd strategy only.

Usage: gen_ll.py [--module <Module>] <inventory.tsv> <out-dir>
  --module  write only <out-dir>/<Module>.ll (e.g. AnalysisModeOverflow), the
            same bytes the full run writes for it.

Every module defines exactly the external functions its C namesake defines,
as forwarders to the core's __m2c_rt_* entry points or as stubs; the
generator modules carry the KLEE/AFL++ intrinsics, main and setjmp/longjmp.

The output is one <Module>.ll per module (Map2CheckFunctions-glue.ll is the
part of Map2CheckFunctions.bc that is not Rust). IMPLEMENTED lists what
forwards to Rust; the rest are stubs until their task lands.
"""
import csv
import os
import sys

HEADER = (
    'target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-'
    'f80:128-n8:16:32:64-S128"\n'
    'target triple = "x86_64-pc-linux-gnu"\n\n'
)

# Canonical C type (inventory.tsv) -> (IR type, ABI extension attribute).
# x86_64 SysV LP64, as clang-16 lowers it: char (signed on x86_64), signed
# char and short are `signext`; unsigned char and unsigned short `zeroext`;
# _Bool is a `zeroext i1` (D7 inherited finding 4). The attribute goes on
# definitions, declarations and call sites alike.
CTYPE = {
    "void": ("void", None),
    "char": ("i8", "signext"), "signed char": ("i8", "signext"),
    "unsigned char": ("i8", "zeroext"), "_Bool": ("i1", "zeroext"),
    "short": ("i16", "signext"), "unsigned short": ("i16", "zeroext"),
    "int": ("i32", None), "unsigned int": ("i32", None),
    "long": ("i64", None), "unsigned long": ("i64", None),
    "long long": ("i64", None), "unsigned long long": ("i64", None),
    "float": ("float", None), "double": ("double", None),
}


class StructByValue(ValueError):
    """A C struct passed or returned by value: no single IR type for it."""


# Runtime-internal C helpers that take or return a struct by value. They have
# no consumer outside the C runtime (referenced_by = runtime), and the Rust
# core keeps that logic private (d7-layout.md, approval item 2). Any other
# signature gen_ll.py cannot translate is a hard error.
STRUCT_BY_VALUE_EXEMPT = {
    "B_TREE_CREATE", "get_element_at", "map2check_nondet_get_log",
    "new_container", "new_heap_row", "new_list_row", "new_memory_row",
    "nondet_log_to_file", "trackbb_new_row",
}


def ir_type(c):
    """C type -> (IR type, 'signext' | 'zeroext' | None)."""
    c = c.strip()
    if c.endswith("*"):
        return ("ptr", None)
    for q in ("const ", "volatile "):
        c = c.replace(q, "")
    c = c.strip()
    if c.startswith("enum "):
        return ("i32", None)  # every enum of the C runtime fits int (x86_64 SysV)
    if c.startswith("struct ") or c.startswith("union "):
        raise StructByValue(f"struct by value: '{c}'")
    if c not in CTYPE:
        raise ValueError(f"no IR type for C type '{c}'")
    return CTYPE[c]


def parse_sig(sig):
    """'char (int, const char *)' -> (('i8', 'signext'), [('i32', None), ('ptr', None)])"""
    sig = sig.split(" | ")[0]
    ret, args = sig.split("(", 1)
    if not args.endswith(")"):
        raise ValueError(f"unparseable signature '{sig}'")
    args = args[:-1].strip()
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
            except StructByValue:
                if row["symbol"] in STRUCT_BY_VALUE_EXEMPT:
                    continue
                sys.exit(f"gen_ll: {row['symbol']}: struct by value outside the exemption list: "
                         f"{row['canonical_signature']}")
            except ValueError as e:
                sys.exit(f"gen_ll: {row['symbol']}: {e}")
            for m in row["module"].split("+"):
                mods.setdefault(m[:-3], []).append((row["symbol"], ret, args))
    return mods


# (module, symbol) -> __m2c_rt_* target in the Rust core. Only entry points
# the core already exports (test_every_forwarder_target_is_a_rust_core_export);
# every other function of a module is a stub until its Phase 2 task.
IMPLEMENTED = {
    ("WitnessGeneration", "generate_aux_files"): "__m2c_rt_witness_generate_aux_files",
    ("WitnessGeneration", "generate_confirmation_file"): "__m2c_rt_witness_generate_confirmation_file",
}
# AnalysisModeOverflow.c (Task 2.3): every function with a consumer outside
# the module. divisionByZeroError and unknown_not_supported are internal to
# the C module (referenced_by '-', SD-22), so they are neither defined nor
# forwarded.
for sym in ("analysis_init", "analysis_destroy", "analysis_is_program_correct",
            "analysis_generate_aux_witness_files", "overflowError",
            *(f"map2check_binop_{op}" for op in ("add", "sub", "mul", "add_uint", "sub_uint",
                                                 "mul_uint", "sdiv", "srem"))):
    IMPLEMENTED[("AnalysisModeOverflow", sym)] = f"__m2c_rt_overflow_{sym}"

# Modules whose symbols are all runtime-internal C helpers (container rows by
# value, log files): the Rust core keeps that logic private, so the module is
# empty. See d7-layout.md, approval item 2.
EMPTY = ["TrackBBLog", "NonDetLog", "PropertyGenerator", "ContainerRealloc",
         "ContainerBTree", "BTree", "AllocationLog", "ListLog", "HeapLog"]


def zero(t):
    return {"void": None, "ptr": "null", "float": "0.0", "double": "0.0"}.get(t, "0")


def typed(t):
    """An IR type as gen_ll passes it around: (type, ext) or a bare type."""
    return t if isinstance(t, tuple) else (t, None)


def as_param(t):
    """Parameter / argument position: 'i8 signext'."""
    ty, ext = typed(t)
    return f"{ty} {ext}" if ext else ty


def as_ret(t):
    """Return position: 'signext i8'."""
    ty, ext = typed(t)
    return f"{ext} {ty}" if ext else ty


def define(sym, ret, args, body):
    params = ", ".join(f"{as_param(t)} %a{i}" for i, t in enumerate(args))
    return f"define {as_ret(ret)} @{sym}({params}) {{\n{body}}}\n\n"


def forwarder(sym, ret, args, target):
    call_args = ", ".join(f"{as_param(t)} %a{i}" for i, t in enumerate(args))
    decl = f"declare {as_ret(ret)} @{target}({', '.join(as_param(t) for t in args)})\n"
    ty = typed(ret)[0]
    if ty == "void":
        body = f"  tail call void @{target}({call_args})\n  ret void\n"
    else:
        body = f"  %r = tail call {as_ret(ret)} @{target}({call_args})\n  ret {ty} %r\n"
    return decl + define(sym, ret, args, body)


def stub(sym, ret, args):
    ty = typed(ret)[0]
    if sym == "analysis_is_program_correct":
        return define(sym, ret, args, f"  ret {ty} 1\n")
    if ty == "void":
        return define(sym, ret, args, "  ret void\n")
    return define(sym, ret, args, f"  ret {ty} {zero(ty)}\n")


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

define void @map2check_crab_assume(i8 signext %e) {
  %x = sext i8 %e to i32
  tail call void @nondet_assume(i32 %x)
  ret void
}

define void @map2check_assume_loop(i8 signext %e) {
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
# ABI attribute of the return types above (see CTYPE): char is signed.
NONDET_EXT = {"char": "signext", "short": "signext", "uchar": "zeroext", "u8": "zeroext",
              "ushort": "zeroext", "u16": "zeroext"}
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
  %ch = call signext i8 @map2check_non_det_char()
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


def gen_none():
    out = [HEADER, "; NonDetGeneratorNone: constants, as NonDetGeneratorNone.c.\n\n"]
    out.append("declare i32 @__map2check_main__()\n\n")
    out.append(define("main", "i32", [], "  %r = call i32 @__map2check_main__()\n  ret i32 0\n"))
    for t in NONE_TYPES:
        ty, _ = NONDET_TYPES[t]
        out.append(define(f"map2check_non_det_{t}", (ty, NONDET_EXT.get(t)), [], f"  ret {ty} {zero(ty)}\n"))
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


def gen_klee():
    out = [HEADER, "; NonDetGeneratorKlee: KLEE intrinsics, as NonDetGeneratorKlee.c.\n\n"]
    out.append("declare i32 @__map2check_main__(i32, ptr)\n\n")
    out.append(define("main", "i32", ["i32", "ptr"],
                      "  %r = call i32 @__map2check_main__(i32 %a0, ptr %a1)\n  ret i32 %r\n"))
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
        out.append(define(f"map2check_non_det_{t}", (ty, NONDET_EXT.get(t)), [],
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
# are the reader's globals, defined in AFL_READER.
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

define zeroext i8 @get_next_input_from_afl() {
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
  %b = call zeroext i8 @get_next_input_from_afl()
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


def gen_afl():
    out = [HEADER, "; NonDetGeneratorAFL: AFL++ persistent mode, as NonDetGeneratorAFL.c.\n\n"]
    out.append(AFL_MAIN)
    out.append(AFL_READER)
    out.append(AFL_REJECT)
    out.append("declare void @nondet_log_init()\ndeclare void @nondet_log_destroy()\n"
               "declare void @__m2c_rt_nondet_log_to_file()\n")
    out.append(cstring(".memname", "__VERIFIER_nondet_memory"))
    out.append("\n")
    for t, (ty, size) in NONDET_TYPES.items():
        out.append(define(f"map2check_non_det_{t}", (ty, NONDET_EXT.get(t)), [],
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


PLAIN = ["AnalysisModeMemtrack", "AnalysisModeMemcleanup", "AnalysisModeOverflow",
         "AnalysisModeAssert", "AnalysisModeNone", "WasmRuntimeStubs",
         "WitnessGeneration", "WitnessGenerationNone"]


def modules(mods):
    """Module name -> function returning its IR text, in output order."""
    out = {"Map2CheckFunctions-glue": lambda: GLUE}
    for m in EMPTY:
        out[m] = (lambda m=m: HEADER + f"; {m}: empty. Its C functions are runtime-internal helpers;\n"
                                       "; the Rust core keeps that logic private.\n")
    for m in PLAIN:
        out[m] = lambda m=m: plain_module(m, mods.get(m, []))
    out["NonDetGeneratorNone"] = gen_none
    out["NonDetGeneratorKlee"] = gen_klee
    out["NonDetGeneratorAFL"] = gen_afl
    return out


USAGE = "usage: gen_ll.py [--module <Module>] <inventory.tsv> <out-dir>"


def main(argv):
    only = None
    if argv[:1] == ["--module"]:
        if len(argv) < 2:
            sys.exit(USAGE)
        only, argv = argv[1], argv[2:]
    if len(argv) != 2:
        sys.exit(USAGE)
    inventory, out_dir = argv
    gens = modules(load_inventory(inventory))
    if only is not None:
        if only not in gens:
            sys.exit(f"gen_ll: unknown module '{only}'; known: {' '.join(gens)}")
        gens = {only: gens[only]}
    os.makedirs(out_dir, exist_ok=True)
    for name, gen in gens.items():
        with open(os.path.join(out_dir, name + ".ll"), "w") as f:
            f.write(gen())


if __name__ == "__main__":
    main(sys.argv[1:])
