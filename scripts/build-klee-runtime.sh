#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Builds the runtime of the Map2Check `symex` generator as one LLVM 16
# bitcode module (D1, route A', docs/cutover/decisoes.md):
#
#   rustc 1.72.1 (LLVM 16) on klee/Cargo.toml with its own Cargo.lock,
#   feature `klee`, panic = abort, fat LTO, codegen-units = 1,
#   --emit=llvm-bc, then `opt-16 --strip-debug` (condition 6), then the
#   vector intrinsics KLEE cannot run lowered to scalar code
#   (scripts/klee-lower-intrinsics.py), then a read-back with `llvm-dis-16`.
#
# Usage: scripts/build-klee-runtime.sh <out.bc>
#
# Environment:
#   KLEE_RUSTC_TOOLCHAIN  rustup toolchain (default 1.72.1)
#   OPT, LLVM_DIS, LLVM_NM, LLVM_AS, LLI  LLVM 16 tools (default opt-16,
#                         llvm-dis-16, llvm-nm-16, llvm-as-16, lli-16)
#   CARGO_TARGET_DIR      target directory (default <repo>/target/klee)
#
# Every step must succeed; the script stops at the first failure and then
# leaves nothing at <out.bc>.
set -euo pipefail

die() {
  echo "build-klee-runtime: error: $*" >&2
  exit 1
}

[ $# -eq 1 ] || die "usage: $0 <out.bc>"
out="$1"
case "$out" in
  *.bc) ;;
  *) die "the output must end in .bc: $out" ;;
esac

# A failed build must not leave an earlier (or partial) runtime behind.
rm -f "$out"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLCHAIN="${KLEE_RUSTC_TOOLCHAIN:-1.72.1}"
OPT="${OPT:-opt-16}"
LLVM_DIS="${LLVM_DIS:-llvm-dis-16}"
LLVM_NM="${LLVM_NM:-llvm-nm-16}"
LLVM_AS="${LLVM_AS:-llvm-as-16}"
LLI="${LLI:-lli-16}"
TARGET_DIR="${CARGO_TARGET_DIR:-$ROOT/target/klee}"

for tool in cargo rustc python3 "$OPT" "$LLVM_DIS" "$LLVM_NM" "$LLVM_AS" "$LLI"; do
  command -v "$tool" >/dev/null || die "$tool not found in PATH"
done

# The bitcode must come from LLVM 16: a newer LLVM writes attributes that
# llvm-link-16 and KLEE 3.1 reject ("Unknown attribute kind (91)").
llvm_version="$(RUSTUP_TOOLCHAIN="$TOOLCHAIN" rustc -vV | sed -n 's/^LLVM version: //p')"
case "$llvm_version" in
  16.*) ;;
  *) die "rustc $TOOLCHAIN uses LLVM '$llvm_version', not 16" ;;
esac

deps="$TARGET_DIR/release/deps"
# Always rebuild the crate itself (not its dependencies): the rustc command
# line checked below only shows up when it is compiled, and a stale module
# would be picked up.
RUSTUP_TOOLCHAIN="$TOOLCHAIN" CARGO_TARGET_DIR="$TARGET_DIR" \
  cargo clean --release -p map2check-klee-runtime \
  --manifest-path "$ROOT/klee/Cargo.toml" >/dev/null 2>&1 || die "cargo clean failed"
if [ -d "$deps" ]; then
  find "$deps" -maxdepth 1 -name 'map2check-*.bc' -delete
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
log="$work/cargo.log"
# --locked: the dependency graph is the one in klee/Cargo.lock (v3), never
# a fresh resolution. The profile (klee/Cargo.toml) sets panic = abort,
# lto = fat and codegen-units = 1; the check below proves rustc got them.
if ! RUSTUP_TOOLCHAIN="$TOOLCHAIN" CARGO_TARGET_DIR="$TARGET_DIR" \
  cargo rustc --locked --release --features klee --lib -v \
  --manifest-path "$ROOT/klee/Cargo.toml" -- --emit=llvm-bc >"$log" 2>&1; then
  cat "$log" >&2
  die "cargo rustc failed"
fi

crate_line="$(grep -E 'Running `.*rustc .*--crate-name map2check ' "$log" | tail -n 1 || true)"
[ -n "$crate_line" ] || { cat "$log" >&2; die "no rustc command line for the map2check crate"; }
for flag in '-C panic=abort' '-C lto' '-C codegen-units=1' '--emit=llvm-bc'; do
  case "$crate_line" in
    *"$flag"*) ;;
    *) die "rustc was not given '$flag': $crate_line" ;;
  esac
done
case "$crate_line" in
  *'-C lto=thin'* | *'-C lto=off'* | *'-C lto=no'*) die "LTO is not fat: $crate_line" ;;
esac

mapfile -t modules < <(find "$deps" -maxdepth 1 -name 'map2check-*.bc')
[ "${#modules[@]}" -eq 1 ] || die "expected one map2check-*.bc in $deps, found ${#modules[@]}"

# The debug info of the precompiled std does not survive llvm-link-16 +
# KLEE ("Broken module found"); only the runtime loses it, the analysed
# program keeps its -g.
# Everything is built in $work and moved to $out only at the end, so a
# failed step never leaves a bitcode behind.
"$OPT" --strip-debug "${modules[0]}" -o "$work/stripped.bc" || die "$OPT --strip-debug failed"
"$LLVM_DIS" "$work/stripped.bc" -o "$work/stripped.ll" || die "$LLVM_DIS cannot read the stripped module"

# KLEE 3.1 cannot execute the vector/x86 intrinsics of the precompiled std
# ("unimplemented intrinsic" in core::fmt padding): replace them by scalar
# functions. The script fails on any remaining intrinsic KLEE 3.1 does not
# execute. Its two self-tests run first: the scalar versions must compute
# what the intrinsics compute (lli-16), and an unknown intrinsic must be
# rejected.
lower="$ROOT/scripts/klee-lower-intrinsics.py"
fixtures="$ROOT/tests/klee"
python3 -I "$lower" "$fixtures/lower-intrinsics.ll" "$work/fixture.ll" >/dev/null ||
  die "the lowering self-test fixture was rejected"
expected="$("$LLI" "$fixtures/lower-intrinsics.ll")" || die "$LLI failed on the fixture"
got="$("$LLI" "$work/fixture.ll")" || die "$LLI failed on the lowered fixture"
[ "$expected" = "$got" ] ||
  die "the scalar versions differ from the intrinsics: '$expected' vs '$got'"
if python3 -I "$lower" "$fixtures/unknown-intrinsic.ll" "$work/unknown.ll" >/dev/null 2>&1; then
  die "the lowering accepted an intrinsic KLEE 3.1 cannot execute (unknown-intrinsic.ll)"
fi
python3 -I "$lower" "$work/stripped.ll" "$work/lowered.ll" ||
  die "lowering the intrinsics failed"
"$LLVM_AS" "$work/lowered.ll" -o "$work/runtime.bc" || die "$LLVM_AS rejected the lowered module"
"$LLVM_DIS" "$work/runtime.bc" -o /dev/null || die "$LLVM_DIS cannot read the lowered module"

# The module must define what the symex pipeline links against, and leave
# the KLEE intrinsics to KLEE.
defined="$("$LLVM_NM" --defined-only "$work/runtime.bc")"
for sym in main __VERIFIER_nondet_int __VERIFIER_nondet_double __VERIFIER_assume \
  __VERIFIER_error map2check_init map2check_set_mode map2check_success; do
  grep -Eq "[[:space:]]$sym\$" <<<"$defined" || die "$out does not define $sym"
done
undefined="$("$LLVM_NM" --undefined-only "$work/runtime.bc")"
for sym in klee_make_symbolic klee_assume __map2check_main__; do
  grep -Eq "[[:space:]]$sym\$" <<<"$undefined" || die "$out does not import $sym"
done

mkdir -p "$(dirname "$out")"
mv -f "$work/runtime.bc" "$out" || die "cannot write $out"
echo "build-klee-runtime: wrote $out (rustc $TOOLCHAIN, LLVM $llvm_version)"
