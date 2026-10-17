; SPDX-License-Identifier: GPL-3.0-only
; Self-test of the guard of scripts/klee-stub-symbolizer.py, run by
; scripts/build-klee-runtime.sh: main (live code) calls a body named after
; std's backtrace printer that is an abort stub. If rustc merged that drop
; with a `String` drop, every format! would abort under KLEE, so `--check`
; must reject this module.
define internal i32 @"_ZN4core3ptr88drop_in_place$LT$std..sys_common..backtrace.._print_fmt..$u7b$$u7b$closure$u7d$$u7d$$GT$17h0000000000000004E"(i32 %x) unnamed_addr #0 {
start:
  call void @abort()
  unreachable
}

define i32 @main() {
start:
  %a = call i32 @"_ZN4core3ptr88drop_in_place$LT$std..sys_common..backtrace.._print_fmt..$u7b$$u7b$closure$u7d$$u7d$$GT$17h0000000000000004E"(i32 42)
  ret i32 %a
}

declare void @abort()

attributes #0 = { cold noinline noreturn nounwind }
