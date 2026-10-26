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

    def _perf_case(self, wall_r=10.0, rss_r=1000, n=5):
        c, r = [], []
        for i in range(n):
            c += rows("d/t%d" % i, wall=10.0, rss=1000)
            r += rows("d/t%d" % i, wall=wall_r, rss=rss_r)
        return self.run_gate(c, r)

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
