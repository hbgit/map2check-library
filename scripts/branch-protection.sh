#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Proteção de branches do repositório (issue #26 / plano M1 DoD).
#   payload <branch>  imprime o JSON desejado (offline)
#   check   <branch>  compara a proteção remota com a desejada (exit 0/1)
#   apply   <branch>  aplica a proteção desejada e roda check
#   encode  <branch>  nome da branch codificado para URL
set -euo pipefail

REPO="${REPO:-hbgit/map2check-library}"
CI_CHECK="${CI_CHECK:-build_and_test}"
CI_APP_ID="${CI_APP_ID:-15368}"

usage() { echo "uso: $0 {payload|check|apply|encode} {develop|master}" >&2; exit 2; }
need()  { command -v "$1" >/dev/null || { echo "erro: '$1' não encontrado" >&2; exit 2; }; }

encode() { jq -rn --arg b "$1" '$b|@uri'; }

payload() {
  local reviews
  case "$1" in
    develop) reviews='null' ;;
    master)       reviews='{"dismiss_stale_reviews":false,"require_code_owner_reviews":false,"required_approving_review_count":1}' ;;
    *) echo "erro: branch sem proteção definida: $1" >&2; exit 2 ;;
  esac
  jq -n --arg ctx "$CI_CHECK" --argjson app "$CI_APP_ID" --argjson reviews "$reviews" '{
    required_status_checks: {strict: false, checks: [{context: $ctx, app_id: $app}]},
    enforce_admins: false,
    required_pull_request_reviews: $reviews,
    restrictions: null,
    allow_force_pushes: false,
    allow_deletions: false
  }'
}

check() {
  local b="$1" want got errs
  want="$(payload "$b")"
  if ! got="$(gh api "repos/$REPO/branches/$(encode "$b")/protection" 2>/dev/null)"; then
    echo "FAIL $b: branch não protegida (ou sem acesso)"; return 1
  fi
  errs="$(jq -r -n --argjson w "$want" --argjson g "$got" --arg b "$b" '
    ($w.required_status_checks.checks[0].context) as $ctx
    | ($w.required_pull_request_reviews.required_approving_review_count // 0) as $rev
    | [ (if ($g.required_status_checks.checks // []) | any(.context == $ctx) then empty
         else "check obrigatório \($ctx) ausente" end),
        (if $g.required_signatures.enabled == true then empty else "assinatura de commits não exigida" end),
        (if $g.allow_force_pushes.enabled == false then empty else "force push permitido" end),
        (if $g.allow_deletions.enabled == false then empty else "deleção permitida" end),
        (if ($g.required_pull_request_reviews.required_approving_review_count // 0) >= $rev then empty
         else "review obrigatório perdido" end) ]
    | .[] | "FAIL \($b): \(.)"')"
  if [ -n "$errs" ]; then echo "$errs"; return 1; fi
  echo "ok $b"
}

apply() {
  local b="$1" enc
  enc="$(encode "$b")"
  payload "$b" | gh api -X PUT "repos/$REPO/branches/$enc/protection" --input - >/dev/null
  gh api -X POST "repos/$REPO/branches/$enc/protection/required_signatures" >/dev/null
  check "$b"
}

need jq
[ $# -eq 2 ] || usage
case "$1" in
  payload) payload "$2" ;;
  encode)  encode "$2" ;;
  check)   need gh; check "$2" ;;
  apply)   need gh; apply "$2" ;;
  *) usage ;;
esac
