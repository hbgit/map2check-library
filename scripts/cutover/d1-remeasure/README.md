# D1 re-measurement (Task 2.5b)

Scripts, programs and raw results of the re-measurement of D1 conditions 3
and 4 (`docs/cutover/decisoes.md`). The write-up is
`docs/cutover/spike-llvm16.md`, section “Remedição (Task 2.5b)”.

Every script runs inside `map2check-dev:cutover-rust` (built from the spike's
`Dockerfile.rust`) with these mounts:

| Mount | What |
|---|---|
| `/src` | this repository, read-write (`build.rs` rewrites `include/map2check.h`) |
| `/runtime` | `modules/backend/library` of the Map2Check `develop` checkout, read-only |
| `/bench` | a **copy** of this directory in a scratch location (the scripts write their builds and campaign outputs there) |
| `/old` | only for `build_old.sh`: a `git worktree` of `0d5b1f6` |

```sh
cp -r scripts/cutover/d1-remeasure "$SCRATCH/bench"
run() { docker run --rm --cpus 4 -v "$PWD":/src \
  -v "$MAP2CHECK/modules/backend/library":/runtime:ro \
  -v "$SCRATCH/bench":/bench map2check-dev:cutover-rust bash "$@"; }
run /bench/build-routes.sh v1     # B1/B2 binaries and the type programs, in build-v1/
run /bench/diff.sh                # differential: 16 types, B1 vs B2 (creates inputs/ and out/)
run /bench/bench.sh build-v1 5    # 40 sequential 30 s campaigns -> stdout TSV
run /bench/seed4.sh               # informative: seed "AAAA", stop at first crash
run /bench/flags16.sh             # -O2 harness per unwind flag (clang-16, afl-clang-fast)
```

`build_old.sh` needs the extra `-v "$WORKTREE":/old` mount.

| File | Role |
|---|---|
| `prog42.c`, `prog42_c.c` | the spike's program for B1 and as the passes leave it for B2 |
| `assume.c`, `assume_c.c` | the assume-heavy program, same two forms |
| `types_b1.c`, `types_b2.c` | read one value of each nondet type and print it |
| `results/results-v1.tsv` | raw stats of the 40 campaigns |
| `results/corpus-v1.tsv` | `corpus_count` and queue entries of the same 40 campaigns |
| `results/results-old.tsv` | baseline with the library before Task 2.5b |
| `results/results-seed4.tsv` | informative runs with the 4-byte seed |
| `results/differential.txt` | output of `diff.sh` |
| `results/flags16.txt` | output of `flags16.sh` (fix round 1) |
