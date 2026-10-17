; SPDX-License-Identifier: GPL-3.0-only
; Self-test of scripts/klee-stub-symbolizer.py, run by
; scripts/build-klee-runtime.sh (and so by the CI job klee_runtime) with
; lli-16 before and after the rewrite:
;   - no argument: main returns 42 through @shared, a body named after a
;     gimli type that the remaining code also calls (rustc merges identical
;     functions); it must keep its body, so 42 before and after;
;   - one argument: main calls the backtrace printer, which calls the
;     symbolizer; 42 before, an abort (SIGABRT) after;
;   - `--check` rejects this file as it is and accepts the rewritten one.
@vtable = internal constant [1 x ptr] [ptr @_ZN3std10sys_common9backtrace5print17h0000000000000001E]

define internal i32 @_ZN5gimli4read5parse17h0000000000000002E(i32 %x) unnamed_addr #0 personality ptr @rust_eh_personality {
start:
  %y = mul i32 %x, 2
  %z = sub i32 %y, 42
  ret i32 %z
}

define internal i32 @_ZN3std10sys_common9backtrace5print17h0000000000000001E(i32 %x) unnamed_addr #0 {
start:
  %r = call i32 @_ZN5gimli4read5parse17h0000000000000002E(i32 %x)
  ret i32 %r
}

define internal i32 @"_ZN4core3ptr13drop_in_place$LT$gimli..Mapping$GT$17h0000000000000003E"(i32 %x) unnamed_addr #0 {
start:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @rust_eh_personality() {
  ret i32 0
}

define i32 @main(i32 %argc, ptr %argv) {
start:
  %a = call i32 @"_ZN4core3ptr13drop_in_place$LT$gimli..Mapping$GT$17h0000000000000003E"(i32 41)
  %bt = icmp sgt i32 %argc, 1
  br i1 %bt, label %print, label %done

print:
  %f = load ptr, ptr @vtable
  %p = call i32 %f(i32 %a)
  ret i32 %p

done:
  ret i32 %a
}

attributes #0 = { nounwind willreturn memory(none) }
