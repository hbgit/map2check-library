# Verify and Resolve GitHub PR #2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Synchronize branch `feat/update_rust` with base `feature/rust`, resolve the CI license and `cargo-audit` toolchain failures, verify all 45 Rust unit tests and the 53-symbol C FFI ASan/UBSan stress harness, and push to GitHub so that PR #2 passes all checks.

**Architecture:** Merge base branch `origin/feature/rust` into `feat/update_rust` to incorporate commit `417441b` (`GPL-3.0-only` in `deny.toml`). Update `.github/workflows/CI.yml` and `Dockerfile` to install pre-built `cargo-audit` via `taiki-e/install-action@v2` (preventing cargo from failing to compile `cargo-audit` 0.22+ against the pinned `rustc 1.82.0`). Validate locally with unit tests, ASan/UBSan C harness, and Docker build before pushing upstream and confirming green GitHub Actions checks.

**Tech Stack:** Rust 1.82.0, Cargo, cbindgen, Clang 14+ (AddressSanitizer, UndefinedBehaviorSanitizer), Docker, GitHub Actions, `taiki-e/install-action@v2`, cargo-deny.

**Spec:** GitHub PR #2 (`hbgit/map2check-library#2`), CI runs `37540751384` and `38329157424`.

## Global Constraints

- Pinned toolchain: Rust 1.82.0 (defined in `rust-toolchain.toml`).
- C ABI exports: 53 exported symbols from `rust/src/ffi.rs` and `rust/src/nondet/libfuzzer.rs`.
- Zero tolerance for panic escape across `extern "C"` boundary (`ffi_guard` wrapper).
- SPDX license headers: `GPL-3.0-only` across all Rust and C files.
- Memory safety: Clean execution under `clang -fsanitize=address,undefined`.

## Review Focus

1. **`cargo-audit` installation failure with Rust 1.82**: `rustsec/audit-check@v2` triggers `cargo install cargo-audit` (latest 0.22.2 requiring rustc >= 1.88); must use prebuilt binary via `taiki-e/install-action@v2` or compatible locked version.
2. **`deny.toml` license rejection**: Missing `GPL-3.0-only` causes `cargo deny check` license failure; must include `GPL-3.0-only` in `deny.toml`.
3. **`Dockerfile` builder stage toolchain failure**: Stage 1 attempting `cargo install cargo-audit` inside `rust:1.82-slim-bookworm` fails for the same reason; must clean up Stage 1 dependencies.
4. **FFI hostile input resilience**: Malformed and pre-init inputs to `tests/ffi_harness.c` must not trigger aborts, assertion failures, or memory leaks under AddressSanitizer and UndefinedBehaviorSanitizer.
5. **Reentrancy and state poisoning**: `map2check_reset()` must clear mutex poison after any handled panic and reset all containers.

---

### Task 1: Synchronize `feat/update_rust` with Base Branch `feature/rust`

**Files:**
- Modify: `deny.toml:1-15` (merged from `feature/rust`)
- Test: Local git merge verification

**Interfaces:**
- Consumes: `origin/feature/rust` commit `417441b` (`Allow GPL-3.0-only in cargo-deny policy (#4)`)
- Produces: Updated `feat/update_rust` with `GPL-3.0-only` allowed in `deny.toml` and clean git merge history

- [ ] **Step 1: Verify current branch and fetch latest remotes**

Run:
```bash
git fetch origin
git checkout feat/update_rust
git status
```
Expected: On branch `feat/update_rust`, working tree clean.

- [ ] **Step 2: Merge `origin/feature/rust` into `feat/update_rust`**

Run:
```bash
git merge origin/feature/rust --no-edit -m "Merge branch 'feature/rust' into feat/update_rust"
```
Expected: Automatic merge succeeds with 0 conflicts. `deny.toml` now contains `GPL-3.0-only`.

- [ ] **Step 3: Verify `deny.toml` contains `GPL-3.0-only`**

Run:
```bash
grep -F "GPL-3.0-only" deny.toml
```
Expected: `"GPL-3.0-only"` is present in the `licenses.allow` list.

- [ ] **Step 4: Run unit tests to confirm merge integrity**

Run:
```bash
cargo test --all-features
```
Expected: All 45 tests pass (`test result: ok. 45 passed; 0 failed`).

---

### Task 2: Fix CI Workflow and Dockerfile for Rust 1.82 Toolchain Compatibility

**Files:**
- Modify: `.github/workflows/CI.yml:35-46`
- Modify: `Dockerfile:10-12`
- Test: Local Docker build and workflow file validation

**Interfaces:**
- Consumes: `rust-toolchain.toml` channel `1.82.0`
- Produces: Working CI step for `cargo-audit` that does not attempt to compile `cargo-audit 0.22.2` from source, and reproducible `docker build .`

- [ ] **Step 1: Check the failing CI configuration in `.github/workflows/CI.yml`**

Run:
```bash
grep -n -C 5 "cargo-audit" .github/workflows/CI.yml
```
Expected: Shows `uses: rustsec/audit-check@v2` without pre-installed `cargo-audit`.

- [ ] **Step 2: Update `.github/workflows/CI.yml` to use `taiki-e/install-action@v2` for `cargo-audit`**

In `.github/workflows/CI.yml`, replace the `Auditoria de segurança (cargo-audit)` step with:
```yaml
      - name: Instalar cargo-audit
        uses: taiki-e/install-action@v2
        with:
          tool: cargo-audit

      - name: Auditoria de segurança (cargo-audit)
        run: cargo audit
```

- [ ] **Step 3: Update `Dockerfile` to prevent compiling incompatible `cargo-audit` in Stage 1**

In `Dockerfile`, line 11:
Replace:
```dockerfile
RUN rustup component add clippy rustfmt && \
    cargo install cargo-tarpaulin cargo-audit cargo-deny cbindgen
```
With:
```dockerfile
RUN rustup component add clippy rustfmt && \
    cargo install cbindgen
```
*(Note: `cbindgen` is the only cargo tool needed in Stage 1 to generate `include/map2check.h`; `cargo-tarpaulin` is installed in Stage 2 if needed, while `cargo-audit` and `cargo-deny` are CI lint tools not used in the container image build.)*

- [ ] **Step 4: Verify Dockerfile builds locally**

Run:
```bash
docker build -t map2check-library:test .
```
Expected: Build finishes successfully and outputs `naming to docker.io/library/map2check-library:test done`.

- [ ] **Step 5: Commit CI and Dockerfile updates**

Run:
```bash
git add .github/workflows/CI.yml Dockerfile
git commit -m "ci: fix cargo-audit installation for rust 1.82 and optimize Dockerfile"
```
Expected: Commit created successfully.

---

### Task 3: Local End-to-End Verification (Tests & Sanitizers)

**Files:**
- Test: `tests/ffi_harness.c`
- Test: `rust/src/`

**Interfaces:**
- Consumes: `libmap2check.a`, `include/map2check.h`, `tests/ffi_harness.c`
- Produces: Verified static library, generated C header, clean sanitizer execution

- [ ] **Step 1: Run complete Rust test suite**

Run:
```bash
cargo test --all-features
```
Expected: 45 passed; 0 failed.

- [ ] **Step 2: Build release library and generate header**

Run:
```bash
cargo build --release --all-features
```
Expected: Compiles with release optimizations; `include/map2check.h` generated.

- [ ] **Step 3: Compile and run C FFI stress harness under ASan and UBSan**

Run:
```bash
clang -fsanitize=address,undefined -fno-omit-frame-pointer \
  tests/ffi_harness.c target/release/libmap2check.a \
  -ldl -lpthread -lm -o target/ffi_harness
./target/ffi_harness
```
Expected: Harness runs both hostile and valid rounds, executes 2 consecutive LibFuzzer runs, exits with code 0 without any ASan/UBSan reports.

- [ ] **Step 4: Check git status to ensure working directory is clean**

Run:
```bash
git status
```
Expected: Working tree clean, branch ahead of `origin/feat/update_rust`.

---

### Task 4: Push to Remote and Validate PR #2 GitHub Actions

**Files:**
- Remote: `origin/feat/update_rust` (PR #2)

**Interfaces:**
- Consumes: Local commits on `feat/update_rust`
- Produces: Updated GitHub PR #2 with green CI status checks

- [ ] **Step 1: Push changes to `origin/feat/update_rust`**

Run:
```bash
git push origin feat/update_rust
```
Expected: Commits pushed successfully to `origin/feat/update_rust`.

- [ ] **Step 2: Monitor GitHub Actions workflow run for PR #2**

Run:
```bash
gh pr checks 2
```
Expected: Watch workflow until completed. All checks report SUCCESS:
- `CI Map2Check Rust / build_and_test`: SUCCESS
- `GitGuardian Security Checks`: SUCCESS

- [ ] **Step 3: Verify PR #2 status and review status**

Run:
```bash
gh pr view 2 --json state,mergeable,reviewDecision,statusCheckRollup
```
Expected:
- `state`: "OPEN"
- `mergeable`: "MERGEABLE"
- `reviewDecision`: "APPROVED"
- `statusCheckRollup`: All checks passing
