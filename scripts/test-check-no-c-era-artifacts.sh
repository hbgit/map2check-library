#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/check-no-c-era-artifacts.sh (issue #27).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/scripts/check-no-c-era-artifacts.sh"
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
# rejects NOME CAMINHO: o guard deve sair 1 e citar o caminho
rejects() {
  local out rc=0
  out="$(printf '%s\n' "$2" | "$CHK" --stdin 2>&1)" || rc=$?
  if [ "$rc" -eq 1 ] && grep -qxF "C-era artifact: $2" <<<"$out"; then ok "$1"; else bad "$1 (rc=$rc out=$out)"; fi
}
# accepts NOME CAMINHO: o guard deve sair 0 sem saída
accepts() {
  local out rc=0
  out="$(printf '%s\n' "$2" | "$CHK" --stdin 2>&1)" || rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "$1"; else bad "$1 (rc=$rc out=$out)"; fi
}

# Artefatos citados na issue
rejects ".clangd" ".clangd"
rejects "compile_commands.json" "compile_commands.json"
rejects ".travis.yml" ".travis.yml"
rejects ".vscode" ".vscode/settings.json"
rejects "Doxyfile" "docs/Doxyfile"
rejects "xmi com espaço (Review Focus 1)" "docs/C map2checklibrary.xmi"
rejects "xmi" "docs/map2checklibrary.xmi"
rejects "diagrama de classes C" "docs/imgs/class-diagram.png"
# Build C/CMake
rejects "CMakeLists" "CMakeLists.txt"
rejects "módulo cmake" "cmake/FindGTest.cmake"
rejects "build.sh" "build.sh"
rejects "run_klee_test.sh" "run_klee_test.sh"
# Aninhados (Review Focus 3)
rejects ".vscode aninhado" "rust/.vscode/launch.json"
rejects "CMakeLists aninhado" "test/CMakeLists.txt"

# Arquivos legítimos da era Rust (Review Focus 2)
accepts "build.rs" "build.rs"
accepts ".cargo/config.toml" ".cargo/config.toml"
accepts "flowchart do README" "docs/imgs/map2check-flowchart.png"
accepts "coverage.sh" "scripts/coverage.sh"
accepts "run_libfuzzer_test.sh" "run_libfuzzer_test.sh"
accepts "api-deltas" "docs/api-deltas.md"

# Lista mista: lista todos os ofensores, um por linha (Review Focus 4)
rc=0
out="$(printf '%s\n' build.rs docs/Doxyfile README.md "docs/C map2checklibrary.xmi" | "$CHK" --stdin 2>&1)" || rc=$?
if [ "$rc" -eq 1 ] && [ "$(grep -c '^C-era artifact: ' <<<"$out")" -eq 2 ]; then ok "lista mista: 2 ofensores"; else bad "lista mista (rc=$rc out=$out)"; fi

# Lista vazia é limpa
rc=0; out="$("$CHK" --stdin </dev/null 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "lista vazia"; else bad "lista vazia (rc=$rc)"; fi

# Argumento inválido → 2
rc=0; "$CHK" --bogus >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then ok "argumento inválido sai 2"; else bad "argumento inválido (rc=$rc)"; fi

# Guard ligado no CI
if grep -qF 'scripts/check-no-c-era-artifacts.sh' "$ROOT/.github/workflows/CI.yml"; then ok "CI roda o guard"; else bad "CI roda o guard"; fi

exit "$fail"
