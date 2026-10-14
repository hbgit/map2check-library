#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Roda o cargo-tarpaulin com o gate de cobertura do projeto.
# Usado pelo CI (.github/workflows/CI.yml) e pelo estágio `test` do Dockerfile.
set -euo pipefail

FAIL_UNDER="${COVERAGE_FAIL_UNDER:-80}"
OUT_DIR="${COVERAGE_OUT_DIR:-coverage}"

exec cargo tarpaulin \
  --engine llvm \
  --all-features \
  --exclude-files 'rust/src/ffi*.rs' \
  --out Lcov --out Html \
  --output-dir "$OUT_DIR" \
  --fail-under "$FAIL_UNDER"
