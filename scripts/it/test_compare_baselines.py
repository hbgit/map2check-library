# SPDX-License-Identifier: GPL-3.0-only
"""Testes de scripts/it/compare_baselines.py (um caso por critério do gate).

Rodar da raiz do repositório:

    python3 -I -m unittest discover -s scripts/it -p 'test_*.py'

Com -I o diretório corrente sai do sys.path, então o módulo é carregado pelo
caminho explícito, ao lado deste arquivo.
"""

import contextlib
import importlib.util
import io
import os
import shutil
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "compare_baselines", os.path.join(HERE, "compare_baselines.py"))
cb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cb)

HEADER = "task\tprp\tgen\trep\tverdict\ttag\tline\tfunction\twitness\twall_s\tmaxrss_kb"
DELTAS_HEADER = "task\tprp\tgen\tfield\tc_value\trust_value\tsd_ref"
SEMANTIC = """# Semantic deltas

### SD-03 — Violations do not stop the analysis; the first one is final

text

### SD-07 — `__VERIFIER_assume(0)` abandons the fuzzer input
"""


def rows(task, prp="valid-memsafety", gen="afl", verdicts=("SUCCEEDED",) * 5,
         tag="", line="", function="", witness=None, wall=10.0, rss=1000):
    """Uma linha TSV por repetição. wall/rss podem ser escalares ou listas."""
    out = []
    for i, v in enumerate(verdicts):
        failed = v == "FAILED"
        w = witness if witness is not None else (1 if v in ("FAILED", "SUCCEEDED") else 0)
        wl = wall[i] if isinstance(wall, (list, tuple)) else wall
        rs = rss[i] if isinstance(rss, (list, tuple)) else rss
        out.append("\t".join([
            task, prp, gen, str(i + 1), v,
            tag if failed else "", str(line) if failed else "",
            function if failed else "", str(w), "%.2f" % wl, str(rs)]))
    return out


class CompareBaselinesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.semantic = self._write("semantic-deltas.md", SEMANTIC)
        self.deltas = self._write("deltas.tsv", DELTAS_HEADER + "\n")
        self.corpus = os.path.join(self.tmp, "corpus")
        os.makedirs(os.path.join(self.corpus, "d"))
        self._yml("d/safe", [("valid-memsafety", "true", None)])
        self._yml("d/bug", [("valid-memsafety", "false", "valid-free")])
        self._yml("d/reach", [("unreach-call", "false", None)])
        for t in ("d/x", "d/t0", "d/t1", "d/t2", "d/t3", "d/t4"):
            self._yml(t, [("valid-memsafety", "true", None)])

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def _write(self, name, text):
        path = os.path.join(self.tmp, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return path

    def _yml(self, task, props):
        lines = ["format_version: '1.0'", "", "input_files: 'x.i'", "", "properties:"]
        for prp, verdict, sub in props:
            lines.append("  - property_file: ../properties/%s.prp" % prp)
            lines.append("    expected_verdict: %s" % verdict)
            if sub:
                lines.append("    subproperty: %s" % sub)
        with open(os.path.join(self.corpus, task + ".yml"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")

    def _tsv(self, name, lines):
        return self._write(name, HEADER + "\n" + "\n".join(lines) + "\n")

    def _deltas(self, entries):
        return self._write("deltas.tsv", DELTAS_HEADER + "\n" +
                           "".join("\t".join(e) + "\n" for e in entries))

    def run_gate(self, c_lines, rust_lines):
        c = self._tsv("c.tsv", c_lines)
        r = self._tsv("rust.tsv", rust_lines)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = cb.main([c, r, "--deltas", self.deltas,
                            "--semantic-deltas", self.semantic,
                            "--corpus", self.corpus])
        out = buf.getvalue().splitlines()
        return code, out

    def criterion(self, out, name):
        hits = [l for l in out if l.startswith(name + ":")]
        self.assertEqual(len(hits), 1, "criterion %r in %r" % (name, out))
        return hits[0]

    def assertGate(self, code, out, passed):
        self.assertEqual(out[-1], "gate: PASS" if passed else "gate: FAIL", out)
        self.assertEqual(code, 0 if passed else 1)

    # --- baseline ----------------------------------------------------------

    def base(self):
        return (rows("d/safe") +
                rows("d/bug", verdicts=("FAILED",) * 5, tag="FALSE-FREE",
                     line=12, function="main") +
                rows("d/reach", prp="unreach-call", verdicts=("FAILED",) * 5,
                     tag="FALSE", line=7, function="__VERIFIER_assert"))

    def test_identical_baselines_pass_with_one_line_per_criterion(self):
        code, out = self.run_gate(self.base(), self.base())
        self.assertGate(code, out, True)
        for name in ("keys", "verdict", "failed-details", "witness", "expected",
                     "deltas", "wall", "timeouts", "rss"):
            self.assertIn("PASS", self.criterion(out, name))

    def test_rep_count_mismatch_fails(self):
        c = rows("d/safe")
        r = rows("d/safe", verdicts=("SUCCEEDED",) * 4)
        code, out = self.run_gate(c, r)
        line = self.criterion(out, "reps")
        self.assertIn("FAIL", line)
        self.assertIn("d/safe", line)
        self.assertGate(code, out, False)

    def test_rep_count_equal_passes(self):
        code, out = self.run_gate(self.base(), self.base())
        self.assertIn("PASS", self.criterion(out, "reps"))

    def _expect_exit2(self, corpus, lines):
        c = self._tsv("c.tsv", lines)
        err = io.StringIO()
        with self.assertRaises(SystemExit) as cm:
            with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
                cb.main([c, c, "--deltas", self.deltas,
                         "--semantic-deltas", self.semantic, "--corpus", corpus])
        self.assertEqual(cm.exception.code, 2)
        return err.getvalue()

    def test_missing_corpus_exits_2(self):
        msg = self._expect_exit2(os.path.join(self.tmp, "nope"), rows("d/safe"))
        self.assertIn("expected_verdict", msg)

    def test_corpus_without_yml_exits_2(self):
        empty = os.path.join(self.tmp, "empty")
        os.makedirs(empty)
        msg = self._expect_exit2(empty, rows("d/safe"))
        self.assertIn("expected_verdict", msg)

    def test_key_without_expectation_exits_2(self):
        msg = self._expect_exit2(self.corpus, rows("d/unlisted"))
        self.assertIn("d/unlisted", msg)

    def test_missing_key_fails(self):
        code, out = self.run_gate(self.base(), rows("d/safe"))
        self.assertIn("FAIL", self.criterion(out, "keys"))
        self.assertGate(code, out, False)

    # --- veredito por moda --------------------------------------------------

    def test_verdict_by_mode_of_five_reps_pass(self):
        c = rows("d/bug", verdicts=("FAILED",) * 5, tag="FALSE-FREE", line=12, function="main")
        r = rows("d/bug", verdicts=("FAILED", "UNKNOWN", "FAILED", "UNKNOWN", "FAILED"),
                 tag="FALSE-FREE", line=12, function="main")
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "verdict"))
        self.assertGate(code, out, True)

    def test_verdict_by_mode_of_five_reps_fail(self):
        c = rows("d/bug", verdicts=("FAILED",) * 5, tag="FALSE-FREE", line=12, function="main")
        r = rows("d/bug", verdicts=("FAILED", "UNKNOWN", "UNKNOWN", "UNKNOWN", "FAILED"),
                 tag="FALSE-FREE", line=12, function="main")
        code, out = self.run_gate(c, r)
        self.assertIn("FAIL", self.criterion(out, "verdict"))
        self.assertGate(code, out, False)

    # --- tag / Line / Function em FAILED -------------------------------------

    def _failed_detail_case(self, **rust):
        args = dict(tag="FALSE-FREE", line=12, function="main")
        c = rows("d/bug", verdicts=("FAILED",) * 5, **args)
        args.update(rust)
        r = rows("d/bug", verdicts=("FAILED",) * 5, **args)
        return self.run_gate(c, r)

    def test_failed_same_details_pass(self):
        code, out = self._failed_detail_case()
        self.assertIn("PASS", self.criterion(out, "failed-details"))
        self.assertGate(code, out, True)

    def test_failed_tag_differs_fails(self):
        code, out = self._failed_detail_case(tag="FALSE-DEREF")
        self.assertIn("FAIL", self.criterion(out, "failed-details"))
        self.assertGate(code, out, False)

    def test_failed_line_differs_fails(self):
        code, out = self._failed_detail_case(line=13)
        self.assertIn("FAIL", self.criterion(out, "failed-details"))
        self.assertGate(code, out, False)

    def test_failed_function_differs_fails(self):
        code, out = self._failed_detail_case(function="free_all")
        self.assertIn("FAIL", self.criterion(out, "failed-details"))
        self.assertGate(code, out, False)

    # --- witness ------------------------------------------------------------

    def test_witness_missing_where_c_had_one_fails(self):
        c = rows("d/safe", witness=1)
        r = rows("d/safe", witness=0)
        code, out = self.run_gate(c, r)
        self.assertIn("FAIL", self.criterion(out, "witness"))
        self.assertGate(code, out, False)

    def test_extra_witness_passes(self):
        c = rows("d/safe", witness=0)
        r = rows("d/safe", witness=1)
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "witness"))
        self.assertGate(code, out, True)

    # --- acertos contra expected_verdict -------------------------------------

    def test_expected_matches_must_not_decrease(self):
        # Divergência de veredito aceita por delta válido, para isolar o critério.
        self._deltas([("d/safe", "valid-memsafety", "afl", "verdict",
                       "SUCCEEDED", "UNKNOWN", "SD-03")])
        c = rows("d/safe")
        r = rows("d/safe", verdicts=("UNKNOWN",) * 5)
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "verdict"))
        self.assertIn("FAIL", self.criterion(out, "expected"))
        self.assertGate(code, out, False)

    def test_expected_matches_increase_passes(self):
        self._deltas([("d/safe", "valid-memsafety", "afl", "verdict",
                       "UNKNOWN", "SUCCEEDED", "SD-03")])
        c = rows("d/safe", verdicts=("UNKNOWN",) * 5)
        r = rows("d/safe")
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "expected"))
        self.assertGate(code, out, True)

    def test_expected_subproperty_requires_matching_tag(self):
        self.assertTrue(cb.matches_expected(("false", "valid-free"), "FAILED", "FALSE-FREE"))
        self.assertFalse(cb.matches_expected(("false", "valid-free"), "FAILED", "FALSE-DEREF"))
        self.assertTrue(cb.matches_expected(("false", None), "FAILED", "FALSE"))
        self.assertTrue(cb.matches_expected(("true", None), "SUCCEEDED", ""))
        self.assertFalse(cb.matches_expected(("true", None), "UNKNOWN", ""))

    # --- deltas aceitos -----------------------------------------------------

    def test_divergence_accepted_with_existing_sd_ref(self):
        self._deltas([("d/bug", "valid-memsafety", "afl", "line", "12", "13", "SD-07")])
        code, out = self._failed_detail_case(line=13)
        self.assertIn("PASS", self.criterion(out, "failed-details"))
        self.assertIn("PASS", self.criterion(out, "deltas"))
        self.assertGate(code, out, True)

    def test_divergence_with_unknown_sd_ref_is_rejected(self):
        self._deltas([("d/bug", "valid-memsafety", "afl", "line", "12", "13", "SD-99")])
        code, out = self._failed_detail_case(line=13)
        self.assertIn("FAIL", self.criterion(out, "failed-details"))
        self.assertIn("FAIL", self.criterion(out, "deltas"))
        self.assertGate(code, out, False)

    # --- desempenho ---------------------------------------------------------

    def _perf_case(self, wall_r=10.0, rss_r=1000, n=5, gen="symex", wall_c=10.0):
        # symex por padrão: o desconto de compilação só vale em afl e hybrid.
        c, r = [], []
        for i in range(n):
            c += rows("d/t%d" % i, gen=gen, wall=wall_c, rss=1000)
            r += rows("d/t%d" % i, gen=gen, wall=wall_r, rss=rss_r)
        return self.run_gate(c, r)

    # --- desconto de compilação (afl e hybrid, decisão de 2026-10-27) --------

    def test_compile_allowance_constant(self):
        self.assertEqual(cb.COMPILE_ALLOWANCE_S, 2.0)
        self.assertEqual(sorted(cb.ALLOWANCE_GENERATORS), ["afl", "hybrid"])

    def test_afl_raw_ratio_above_limit_passes_after_allowance(self):
        # Bruta 3,0/1,0 = 3,0; com desconto (3,0 - 2,0)/1,0 = 1,0.
        code, out = self._perf_case(wall_c=1.0, wall_r=3.0, gen="afl")
        line = self.criterion(out, "wall")
        self.assertIn("PASS", line)
        self.assertIn("2.0 s", line)
        self.assertIn("afl", line)
        self.assertGate(code, out, True)

    def test_hybrid_raw_ratio_above_limit_passes_after_allowance(self):
        code, out = self._perf_case(wall_c=1.0, wall_r=3.0, gen="hybrid")
        self.assertIn("PASS", self.criterion(out, "wall"))
        self.assertGate(code, out, True)

    def test_afl_still_fails_after_allowance(self):
        # (3,2 - 2,0)/1,0 = 1,2 > 1,10.
        code, out = self._perf_case(wall_c=1.0, wall_r=3.2, gen="afl")
        line = self.criterion(out, "wall")
        self.assertIn("FAIL", line)
        self.assertIn("2.0 s", line)
        self.assertGate(code, out, False)

    def test_symex_gets_no_allowance(self):
        # Com desconto daria (3,0 - 2,0)/1,0 = 1,0; sem ele, 3,0.
        code, out = self._perf_case(wall_c=1.0, wall_r=3.0, gen="symex")
        line = self.criterion(out, "wall")
        self.assertIn("FAIL", line)
        self.assertIn("symex", line)
        self.assertGate(code, out, False)

    def test_allowance_boundary_1_10_passes(self):
        code, out = self._perf_case(wall_c=1.0, wall_r=3.1, gen="afl")
        self.assertIn("PASS", self.criterion(out, "wall"))
        self.assertGate(code, out, True)

    def test_allowance_boundary_1_11_fails(self):
        code, out = self._perf_case(wall_c=1.0, wall_r=3.11, gen="hybrid")
        self.assertIn("FAIL", self.criterion(out, "wall"))
        self.assertGate(code, out, False)

    def test_allowance_clamps_at_zero(self):
        # max(1,5 - 2,0, 0) = 0: razão 0, não negativa.
        code, out = self._perf_case(wall_c=1.0, wall_r=1.5, gen="afl")
        line = self.criterion(out, "wall")
        self.assertIn("PASS", line)
        self.assertIn("mediana 0.000", line)
        self.assertGate(code, out, True)

    def test_allowance_is_per_rep_before_median(self):
        # max(x - 2, 0) por repetição: [0, 0, 1, 1, 1] -> mediana 1,0.
        c = rows("d/safe", wall=1.0)
        r = rows("d/safe", wall=[1.0, 1.5, 3.0, 3.0, 3.0])
        code, out = self.run_gate(c, r)
        self.assertIn("mediana 1.000", self.criterion(out, "wall"))

    def test_warning_uses_adjusted_ratio_for_afl(self):
        c, r = [], []
        for i in range(5):
            c += rows("d/t%d" % i, wall=1.0)
            # t0: bruta 3,4, ajustada 1,4 (sem aviso); t1: bruta 3,6, ajustada 1,6.
            r += rows("d/t%d" % i, wall={0: 3.4, 1: 3.6}.get(i, 3.0))
        code, out = self.run_gate(c, r)
        warns = [l for l in out if l.startswith("warning:")]
        self.assertEqual(len(warns), 1, out)
        self.assertIn("d/t1", warns[0])
        self.assertIn("1.60", warns[0])
        self.assertIn("2.0 s", warns[0])

    def test_rss_ignores_allowance(self):
        code, out = self._perf_case(wall_c=1.0, wall_r=3.0, gen="afl", rss_r=1370)
        self.assertIn("FAIL", self.criterion(out, "rss"))

    def test_wall_median_1_10_passes(self):
        code, out = self._perf_case(wall_r=11.0)
        self.assertIn("PASS", self.criterion(out, "wall"))
        self.assertGate(code, out, True)

    def test_wall_median_1_11_fails(self):
        code, out = self._perf_case(wall_r=11.1)
        self.assertIn("FAIL", self.criterion(out, "wall"))
        self.assertGate(code, out, False)

    def test_rss_median_1_36_passes(self):
        code, out = self._perf_case(rss_r=1360)
        self.assertIn("PASS", self.criterion(out, "rss"))
        self.assertGate(code, out, True)

    def test_rss_median_1_37_fails(self):
        code, out = self._perf_case(rss_r=1370)
        self.assertIn("FAIL", self.criterion(out, "rss"))
        self.assertGate(code, out, False)

    def test_wall_is_median_over_reps_then_over_tasks(self):
        # Mediana por tarefa de [10,10,10,30,30] = 10: razão 1,0.
        c = rows("d/safe", wall=10.0)
        r = rows("d/safe", wall=[10.0, 30.0, 10.0, 30.0, 10.0])
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "wall"))
        self.assertGate(code, out, True)

    def test_single_task_ratio_above_1_5_only_warns(self):
        c, r = [], []
        for i in range(5):
            c += rows("d/t%d" % i, wall=10.0, rss=1000)
            r += rows("d/t%d" % i, wall=20.0 if i == 0 else 10.0, rss=1000)
        code, out = self.run_gate(c, r)
        warns = [l for l in out if l.startswith("warning:")]
        self.assertEqual(len(warns), 1, out)
        self.assertIn("d/t0", warns[0])
        self.assertIn("PASS", self.criterion(out, "wall"))
        self.assertGate(code, out, True)

    def test_more_timeouts_fail(self):
        self._deltas([("d/x", "valid-memsafety", "symex", "verdict",
                       "UNKNOWN", "TIMEOUT", "SD-03")])
        c = rows("d/x", gen="symex", verdicts=("UNKNOWN",) * 5)
        r = rows("d/x", gen="symex", verdicts=("TIMEOUT",) * 5)
        code, out = self.run_gate(c, r)
        line = self.criterion(out, "timeouts")
        self.assertIn("FAIL", line)
        self.assertIn("symex", line)
        self.assertGate(code, out, False)

    def test_fewer_timeouts_pass(self):
        self._deltas([("d/x", "valid-memsafety", "symex", "verdict",
                       "TIMEOUT", "UNKNOWN", "SD-03")])
        c = rows("d/x", gen="symex", verdicts=("TIMEOUT",) * 5)
        r = rows("d/x", gen="symex", verdicts=("UNKNOWN",) * 5)
        code, out = self.run_gate(c, r)
        self.assertIn("PASS", self.criterion(out, "timeouts"))
        self.assertGate(code, out, True)

    # --- formato ------------------------------------------------------------

    def test_rejects_tsv_without_eleven_columns(self):
        c = self._write("bad.tsv", HEADER + "\n" + "a\tb\tc\n")
        with self.assertRaises(SystemExit):
            with contextlib.redirect_stderr(io.StringIO()):
                cb.main([c, c, "--deltas", self.deltas,
                         "--semantic-deltas", self.semantic,
                         "--corpus", self.corpus])


if __name__ == "__main__":
    unittest.main()
