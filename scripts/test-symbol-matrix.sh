#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/symbol-matrix.sh (Task 0.3 do cutover), com passes falsos.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/modules/backend/pass"
cat > "$T/modules/backend/pass/P.cpp" <<'CPP'
f("map2check_init"); f("map2check_alloca"); Twine b("map2check_pointer_cast"); f("map2check_unmapped");
CPP
printf 'c_symbol\tcore_symbol\towner_task\tnotes\nmap2check_init\tmap2check_init\t-\t\nmap2check_alloca\tmap2check_map_alloca\t-\t\n' > "$T/map.tsv"
out="$("$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" || true)"
grep -qP '^map2check_init\tmap2check_init\t1$' <<<"$out"
grep -qP '^map2check_alloca\tmap2check_map_alloca\t1$' <<<"$out"
grep -qP '^map2check_unmapped\t-\t0$' <<<"$out"
! grep -q pointer_cast <<<"$out"
if "$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" >/dev/null; then echo "deveria falhar" >&2; exit 1; fi

# Famílias geradas por macro (sem literal de string no fonte) também são símbolos emitidos
cat > "$T/modules/backend/pass/N.hpp" <<'CPP'
#define NON_DET_FUNCTIONS_HELPER(type, c_type) x("map2check_nondet_" #c_type)
NON_DET_FUNCTIONS_HELPER(Integer, int)
NON_DET_FUNCTIONS_HELPER_DOUBLE(Double, double)
CALL_IF_HELPER(Unsigned, UNSIGNED, unsigned)
CPP
out="$("$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" || true)"
grep -qP '^map2check_nondet_int\t-\t0$' <<<"$out"
grep -qP '^map2check_nondet_double\t-\t0$' <<<"$out"
grep -qP '^map2check_non_det_unsigned\t-\t0$' <<<"$out"
! grep -qP '^map2check_nondet_c_type|^map2check_non_det_c_type' <<<"$out"

# Callees sem prefixo conhecido, declarados por getOrInsertFunction (inclusive em várias linhas)
cat > "$T/modules/backend/pass/G.hpp" <<'CPP'
x = M->getOrInsertFunction("overflowError", VoidTy, I32, PtrTy);
y = M->getOrInsertFunction(
    "otherCallee", VoidTy);
CPP
out="$("$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" || true)"
grep -qP '^overflowError\t-\t0$' <<<"$out"
grep -qP '^otherCallee\t-\t0$' <<<"$out"
echo ok
