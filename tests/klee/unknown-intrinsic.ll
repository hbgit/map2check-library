; SPDX-License-Identifier: GPL-3.0-only
; scripts/klee-lower-intrinsics.py must reject this module: KLEE 3.1 does
; not implement llvm.masked.load, and there is no scalar version of it.
declare <2 x i64> @llvm.masked.load.v2i64.p0(ptr, i32, <2 x i1>, <2 x i64>)
define <2 x i64> @f(ptr %p) {
  %v = call <2 x i64> @llvm.masked.load.v2i64.p0(ptr %p, i32 8, <2 x i1> <i1 true, i1 false>, <2 x i64> zeroinitializer)
  ret <2 x i64> %v
}
