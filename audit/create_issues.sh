#!/usr/bin/env bash
# Cria milestones, labels, issues e comentários da auditoria. Dry-run por padrão; use --apply para executar.
set -euo pipefail
REPO=hbgit/map2check-library
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/evidence/created_issues.tsv"
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
run() { if ((APPLY)); then "$@"; else printf 'DRY-RUN:'; printf ' %q' "$@"; echo; fi; }

MILESTONES=(
  "M1 — Restaurar build, CI e higiene"
  "M2 — Endurecer a fronteira FFI"
  "M3 — Completar paridade da API núcleo"
  "M4 — Spike KLEE (gate go/no-go)"
  "M5 — Camada de compatibilidade com passes do Map2Check"
  "M6 — Testes diferenciais e desempenho"
  "M7 — Integração no CMake do Map2Check sob flag"
  "M8 — Promoção a default e aposentadoria do compat"
)
existing_ms=$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title')
for m in "${MILESTONES[@]}"; do
  grep -qxF "$m" <<<"$existing_ms" || run gh api "repos/$REPO/milestones" -f title="$m" --silent
done

LABELS=(area:ffi area:build area:ci area:klee area:fuzzing area:memtrack area:integration
        kind:bug kind:feature kind:test kind:docs prio:critical)
existing_lb=$(gh label list -R "$REPO" --limit 500 --json name --jq '.[].name')
for l in "${LABELS[@]}"; do
  grep -qxF "$l" <<<"$existing_lb" || run gh label create "$l" -R "$REPO"
done

touch "$OUT"
for meta in "$DIR"/issues/*.meta; do
  id=$(basename "$meta" .meta); body="$DIR/issues/$id.md"
  get() { sed -n "s/^$1=//p" "$meta"; }
  ACTION=$(get ACTION); NUMBER=$(get NUMBER); TITLE=$(get TITLE); MILESTONE=$(get MILESTONE); LABELS=$(get LABELS)
  if [[ "$ACTION" == comment ]]; then
    if gh issue view "$NUMBER" -R "$REPO" --json comments --jq '.comments[].body' | grep -qF "Audit-ID: $id"; then
      echo "SKIP $id (comentário já existe em #$NUMBER)"; continue
    fi
    run gh issue comment "$NUMBER" -R "$REPO" -F "$body"
    if ((APPLY)); then printf '%s\t%s\t%s\tcomment\n' "$id" "$NUMBER" "https://github.com/$REPO/issues/$NUMBER" | tee -a "$OUT"; fi
    continue
  fi
  found=$(gh issue list -R "$REPO" --state all --limit 1000 --search "\"Audit-ID: $id\" in:body" --json number --jq '.[0].number // empty')
  # a busca do GitHub indexa issues novas com atraso; o registro local cobre a janela
  [[ -z "$found" ]] && found=$(awk -F'\t' -v i="$id" '$1==i && $4=="create"{print $2}' "$OUT")
  if [[ -n "$found" ]]; then echo "SKIP $id (já existe #$found)"; continue; fi
  if ((APPLY)); then
    url=$(gh issue create -R "$REPO" -t "$TITLE" -m "$MILESTONE" -l "$LABELS" -F "$body")
    printf '%s\t%s\t%s\tcreate\n' "$id" "${url##*/}" "$url" | tee -a "$OUT"
  else
    run gh issue create -R "$REPO" -t "$TITLE" -m "$MILESTONE" -l "$LABELS" -F "$body"
  fi
done
