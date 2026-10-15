#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/branch-protection.sh (não chama a API do GitHub).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BP="$ROOT/scripts/branch-protection.sh"
fail=0
ok()  { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
t()   { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }

# Codificação de nomes com barra (Review Focus 2)
t "encode release/1.0" test "$("$BP" encode release/1.0)" = "release%2F1.0"
t "encode develop"     test "$("$BP" encode develop)" = "develop"
t "encode master"      test "$("$BP" encode master)" = "master"

# develop (integração): check obrigatório, sem review, sem force push/deleção
dv="$("$BP" payload develop 2>/dev/null || true)"
t "develop: check build_and_test (app 15368)" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$dv"
t "develop: strict false"          jq -e '.required_status_checks.strict == false' <<<"$dv"
t "develop: sem review"            jq -e '.required_pull_request_reviews == null' <<<"$dv"
t "develop: enforce_admins false"  jq -e '.enforce_admins == false' <<<"$dv"
t "develop: sem force push"        jq -e '.allow_force_pushes == false and .allow_deletions == false' <<<"$dv"
t "develop: restrictions null"     jq -e 'has("restrictions") and .restrictions == null' <<<"$dv"


# master: mesmo check e preserva 1 review (Review Focus 1)
ms="$("$BP" payload master 2>/dev/null || true)"
t "master: check build_and_test" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$ms"
t "master: 1 review preservado"  jq -e '.required_pull_request_reviews.required_approving_review_count == 1' <<<"$ms"
t "master: enforce_admins false" jq -e '.enforce_admins == false' <<<"$ms"

# Branch desconhecida (inclui a antiga integração) e subcomando inválido falham (Review Focus 5)
t "feature/rust aposentada -> exit 2" bash -c '"$0" payload feature/rust; test $? -eq 2' "$BP"
t "branch desconhecida -> exit 2"     bash -c '"$0" payload feat/x; test $? -eq 2' "$BP"
t "subcomando inválido -> exit 2"     bash -c '"$0" frobnicate master; test $? -eq 2' "$BP"

# O check obrigatório existe como job no CI (Review Focus 3)
t "CI.yml tem job build_and_test" grep -qE '^  build_and_test:' "$ROOT/.github/workflows/CI.yml"

# CI dispara em push e PR para as branches protegidas; senão o check nunca chega
for ev in push pull_request; do
  t "CI.yml: $ev cobre develop e master" bash -c \
    'sed -n "/^  $1:/,/branches:/p" "$0" | grep "branches:" | grep -q "\"develop\"" &&
     sed -n "/^  $1:/,/branches:/p" "$0" | grep "branches:" | grep -q "\"master\""' \
    "$ROOT/.github/workflows/CI.yml" "$ev"
  t "CI.yml: $ev não cita feature/rust" bash -c \
    '! sed -n "/^  $1:/,/branches:/p" "$0" | grep -q "feature/rust"' \
    "$ROOT/.github/workflows/CI.yml" "$ev"
done


exit "$fail"
