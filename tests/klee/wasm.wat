;; SPDX-License-Identifier: GPL-3.0-only
;; A minimal module for tests/klee_paths.sh: what Map2Check's --wasm mode
;; lifts with wasm2c, with the two calls its MemoryTrackPass inserts written
;; as imports (env.track after the allocator, env.check before every access).
;; _start "allocates" the 40-byte block at offset 16, writes inside it, then
;; writes 4 bytes at offset 56, one past the block's end.
(module
  (import "env" "track" (func $track (param i64 i64)))
  (import "env" "check" (func $check (param i64 i64)))
  (memory 1)
  (func (export "_start")
    (call $track (i64.const 16) (i64.const 40))
    (call $check (i64.const 16) (i64.const 4))
    (i32.store (i32.const 16) (i32.const 42))
    (call $check (i64.const 52) (i64.const 4))
    (i32.store (i32.const 52) (i32.const 7))
    (call $check (i64.const 56) (i64.const 4))
    (i32.store (i32.const 56) (i32.const 999))))
