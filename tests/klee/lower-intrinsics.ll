; SPDX-License-Identifier: GPL-3.0-only
; scripts/test-klee-postprocess.sh (and so the CI job klee_runtime) runs this
; with lli-16 before and after scripts/klee-lower-intrinsics.py: the outputs
; must be identical, or the build fails.
declare i64 @llvm.vector.reduce.add.v4i64(<4 x i64>)
declare i64 @llvm.vector.reduce.or.v2i64(<2 x i64>)
declare i64 @llvm.vector.reduce.add.v2i64(<2 x i64>)
declare <8 x i16> @llvm.x86.sse2.pmulhu.w(<8 x i16>, <8 x i16>)
declare void @llvm.x86.sse2.pause()
declare i32 @printf(ptr, ...)
@f = private constant [29 x i8] c"%lld %lld %d %d %d %d %d %d\0A\00"
define i32 @main() {
  %a = call i64 @llvm.vector.reduce.add.v4i64(<4 x i64> <i64 1, i64 20, i64 300, i64 -4000>)
  %b0 = call i64 @llvm.vector.reduce.or.v2i64(<2 x i64> <i64 1, i64 256>)
  %c = call i64 @llvm.vector.reduce.add.v2i64(<2 x i64> <i64 1000000, i64 -7>)
  %b = add i64 %b0, %c
  %m = call <8 x i16> @llvm.x86.sse2.pmulhu.w(<8 x i16> <i16 -1, i16 1000, i16 3, i16 4, i16 5, i16 6, i16 7, i16 -2>, <8 x i16> <i16 -1, i16 1000, i16 3, i16 4, i16 5, i16 6, i16 7, i16 -3>)
  %m0 = extractelement <8 x i16> %m, i32 0
  %m1 = extractelement <8 x i16> %m, i32 1
  %m7 = extractelement <8 x i16> %m, i32 7
  %z0 = zext i16 %m0 to i32
  %z1 = zext i16 %m1 to i32
  %z7 = zext i16 %m7 to i32
  call void @llvm.x86.sse2.pause()
  call i32 (ptr, ...) @printf(ptr @f, i64 %a, i64 %b, i32 %z0, i32 %z1, i32 %z7, i32 0, i32 0, i32 0)
  ret i32 0
}
