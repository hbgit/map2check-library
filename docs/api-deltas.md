# API deltas — `feature/rust` vs. the legacy C `map2check-library`

Tracks intentional gaps and design decisions in the Rust core API relative to
the paridade table in `Logs/plano_map2check_library_rust.md` (§1.2a), as
required by the M3 acceptance criteria ("nm diff ... sem 'Ausente'
injustificado").

## Discontinued: `map2check_gen_data_fuzzer_pchar` / `_loff_t` / `_sector_t`

**Status:** discontinued, not ported to `feature/rust`.

The legacy C library exposed LibFuzzer-backed nondet generators for a few
Linux-kernel/POSIX-specific types (`pchar`, `loff_t`, `sector_t`) alongside
the generic numeric ones. `feature/rust` replaces the whole
`map2check_gen_data_fuzzer_*` family with the SV-COMP-standard
`__VERIFIER_nondet_*` functions (`rust/src/nondet/libfuzzer.rs`), which cover
every portable numeric/bool/pointer type. `pchar`/`loff_t`/`sector_t` have no
portable Rust equivalent (they are kernel ABI types, not part of any target
this library instruments), and no consumer in this repository or in
`Map2Check@develop`'s passes references them. Reintroducing them would mean
adding non-portable, untested surface area for a use case nobody currently
exercises.

**Decision:** do not implement. If a concrete consumer appears, add a
`__VERIFIER_nondet_*`-style generator for the specific width needed instead
of resurrecting the old kernel-typed names.

## Accepted: `__VERIFIER_assume` / `map2check_fuzzer_assume` end the process

`__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` call
`std::process::exit(0)` instead of unwinding back to the caller. LibFuzzer
runs many inputs within a single process, and this crate builds with
`panic = "abort"` in release (`Cargo.toml`), so there is no portable way to
unwind out of an arbitrarily deep call stack back to
`LLVMFuzzerTestOneInput` when an assumption is violated. This matches the
convention used by SV-COMP's native/concrete-execution harnesses. It does end
the fuzzing campaign for the current process — accepted as a known
limitation; full symbolic-execution semantics (path pruning under KLEE) is
deferred to the M4 KLEE spike. See doc comments in
`rust/src/nondet/libfuzzer.rs`.

## Accepted: `map2check_map_non_static_alloca` / `map2check_map_funct_address` semantics

The legacy C headers that defined these symbols
(`container_memtracklog.h:44,48`) no longer exist in this repository (the
`master` C branch's history was not carried over). Their signatures and exact
semantics were reconstructed from the paridade table and from the existing
`map2check_map_alloca`/`map2check_map_malloc` patterns in
`rust/src/ffi.rs`, not from the original C source:

- `map2check_map_non_static_alloca` — same shape as `map2check_map_alloca`,
  but the resulting entry is marked dynamic (`entry.set_malloc()`), so
  `map2check_check_mem_endprog` accounts for it like a heap allocation
  instead of a plain stack slot.
- `map2check_map_funct_address` — registers a function's address as an
  always-valid load target (pointer-width `size_destiny`), so that reading a
  function pointer through `map2check_check_load`/`map2check_check_deref`
  does not get flagged as an invalid address.

**Risk:** if the M5 compatibility layer (`ffi_compat.rs`, consuming the exact
signatures the Map2Check LLVM passes insert) reveals a different expected
semantics, this section documents the M3 baseline that was changed and why.

## Accepted: `char` ABI is `i8`, not the legacy `u8`

`map2check_save_nondet_log_char` now takes `i8` (matching
`__VERIFIER_nondet_char() -> i8`, already `i8` before this change) instead of
`u8`. C's `char` is platform-defined (signed on x86/x86_64, unsigned by
default on most ARM targets); this crate follows the more common
x86/x86_64 convention and does not special-case ARM. If Map2Check ever
targets a plain-`char`-is-unsigned platform, this will need a
target-specific cfg.
