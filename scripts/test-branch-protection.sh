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
t "encode feature/rust"  test "$("$BP" encode feature/rust)" = "feature%2Frust"
t "encode master"        test "$("$BP" encode master)" = "master"

# feature/rust: check obrigatório, sem review, sem force push/deleção
fr="$("$BP" payload feature/rust 2>/dev/null || true)"
t "fr: check build_and_test (app 15368)" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$fr"
t "fr: strict false"          jq -e '.required_status_checks.strict == false' <<<"$fr"
t "fr: sem review"            jq -e '.required_pull_request_reviews == null' <<<"$fr"
t "fr: enforce_admins false"  jq -e '.enforce_admins == false' <<<"$fr"
t "fr: sem force push"        jq -e '.allow_force_pushes == false and .allow_deletions == false' <<<"$fr"
t "fr: restrictions null"     jq -e 'has("restrictions") and .restrictions == null' <<<"$fr"

# master: mesmo check e preserva 1 review (Review Focus 1)
ms="$("$BP" payload master 2>/dev/null || true)"
t "master: check build_and_test" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$ms"
t "master: 1 review preservado"  jq -e '.required_pull_request_reviews.required_approving_review_count == 1' <<<"$ms"
t "master: enforce_admins false" jq -e '.enforce_admins == false' <<<"$ms"

# Branch desconhecida e subcomando inválido falham (Review Focus 5)
t "branch desconhecida -> exit 2" bash -c '"$0" payload develop; test $? -eq 2' "$BP"
t "subcomando inválido -> exit 2" bash -c '"$0" frobnicate master; test $? -eq 2' "$BP"

# O check obrigatório existe como job no CI (Review Focus 3)
t "CI.yml tem job build_and_test" grep -qE '^  build_and_test:' "$ROOT/.github/workflows/CI.yml"

exit "$fail"
