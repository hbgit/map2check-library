#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Gate de comparação entre duas linhas de base do corpus (C contra Rust).

Uso (da raiz do repositório):

    python3 -I scripts/it/compare_baselines.py <c.tsv> <rust.tsv> \\
        --deltas docs/cutover/deltas-aceitos.tsv \\
        [--semantic-deltas docs/semantic-deltas.md] [--corpus <dir sv-benchmarks>]

Entradas: TSVs de 11 colunas produzidos por scripts/it/run-corpus.sh
(task prp gen rep verdict tag line function witness wall_s maxrss_kb).
Os vereditos esperados vêm dos .yml do corpus (--corpus; padrão: a cópia
somente leitura em vendor/map2check), não do TSV: task é o caminho do .yml
relativo ao corpus sem a extensão e prp é o nome do .prp sem a extensão.

Agregação: cada chave (task, prp, gen) é reduzida pela moda das repetições
(veredito; witness; (tag, line, function) entre as repetições FAILED). Empate
na moda: vence o menor valor em ordem lexicográfica, para o resultado não
depender da ordem das linhas. Tempo e RSS: mediana das repetições por chave;
as razões rust/c por chave entram numa mediana global.

Critérios (uma linha cada, `<nome>: PASS|FAIL <detalhe>`):
  keys            mesmo conjunto de chaves nos dois TSVs
  verdict         veredito por moda igual
  failed-details  tag, line e function iguais quando ambos dão FAILED
  witness         witness presente onde o C gerou um
  expected        acertos contra expected_verdict, por gerador, não diminuem
  deltas          toda linha de deltas-aceitos.tsv cita um SD-xx existente
  wall            mediana de wall_rust/wall_c <= 1,10
  timeouts        contagem de TIMEOUT (vereditos por moda) por gerador não aumenta
  rss             mediana de maxrss_rust/maxrss_c <= 1,36
Divergências em verdict/failed-details/witness só passam com uma linha em
deltas-aceitos.tsv (task prp gen field c_value rust_value sd_ref) cujo sd_ref
existe como título `SD-xx` em docs/semantic-deltas.md. Uma chave isolada com
razão > 1,5 gera só uma linha `warning:`. Última linha: `gate: PASS` ou
`gate: FAIL`; código de saída 0 ou 1.
"""

import argparse
import os
import re
import statistics
import sys
from collections import Counter

COLUMNS = ["task", "prp", "gen", "rep", "verdict", "tag", "line", "function",
           "witness", "wall_s", "maxrss_kb"]
DELTA_COLUMNS = ["task", "prp", "gen", "field", "c_value", "rust_value", "sd_ref"]
WALL_MAX = 1.10
RSS_MAX = 1.36
WARN_RATIO = 1.5
EPS = 1e-9

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DEFAULT_SEMANTIC = os.path.join(ROOT, "docs", "semantic-deltas.md")
DEFAULT_CORPUS = os.path.join(ROOT, "vendor", "map2check", "tests", "regression_test",
                              "test_cases", "sv-benchmarks")

# Subpropriedade de valid-memsafety -> tag impressa pelo Map2Check.
SUBPROPERTY_TAG = {
    "valid-free": "FALSE-FREE",
    "valid-deref": "FALSE-DEREF",
    "valid-memtrack": "FALSE-MEMTRACK",
    "valid-memcleanup": "FALSE-MEMCLEANUP",
}


def die(msg):
    print("compare_baselines: " + msg, file=sys.stderr)
    sys.exit(2)


def read_tsv(path, columns):
    with open(path, encoding="utf-8") as f:
        lines = [l.rstrip("\n") for l in f if l.strip()]
    if not lines or lines[0].split("\t") != columns:
        die("%s: cabeçalho esperado: %s" % (path, " ".join(columns)))
    out = []
    for n, l in enumerate(lines[1:], start=2):
        fields = l.split("\t")
        if len(fields) != len(columns):
            die("%s:%d: %d colunas, esperado %d" % (path, n, len(fields), len(columns)))
        out.append(dict(zip(columns, fields)))
    return out


def mode(values):
    counts = Counter(values)
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]


def aggregate(rows):
    """{(task, prp, gen): resumo por moda/mediana das repetições}."""
    groups = {}
    for r in rows:
        groups.setdefault((r["task"], r["prp"], r["gen"]), []).append(r)
    out = {}
    for key, rs in groups.items():
        failed = [(r["tag"], r["line"], r["function"]) for r in rs if r["verdict"] == "FAILED"]
        tag, line, function = mode(failed) if failed else ("", "", "")
        out[key] = {
            "verdict": mode([r["verdict"] for r in rs]),
            "tag": tag, "line": line, "function": function,
            "witness": mode([r["witness"] for r in rs]),
            "wall": statistics.median(float(r["wall_s"]) for r in rs),
            "rss": statistics.median(float(r["maxrss_kb"]) for r in rs),
        }
    return out


def sd_ids(path):
    with open(path, encoding="utf-8") as f:
        return set(re.findall(r"^#+\s+(SD-\d+)\b", f.read(), re.M))


def load_expected(corpus):
    """{(task, prp): (expected_verdict, subproperty|None)} lido dos .yml."""
    out = {}
    if not corpus or not os.path.isdir(corpus):
        return out
    for dirpath, _, files in os.walk(corpus):
        for name in files:
            if not name.endswith(".yml"):
                continue
            path = os.path.join(dirpath, name)
            task = os.path.relpath(path, corpus)[:-len(".yml")]
            prp = None
            with open(path, encoding="utf-8") as f:
                for raw in f:
                    line = raw.split("#", 1)[0].strip()
                    m = re.match(r"-?\s*property_file:\s*(\S+)", line)
                    if m:
                        prp = os.path.basename(m.group(1).strip("'\""))
                        prp = prp[:-len(".prp")] if prp.endswith(".prp") else prp
                        continue
                    m = re.match(r"expected_verdict:\s*(\S+)", line)
                    if m and prp:
                        out[(task, prp)] = (m.group(1).strip("'\"").lower(), None)
                        continue
                    m = re.match(r"subproperty:\s*(\S+)", line)
                    if m and prp and (task, prp) in out:
                        out[(task, prp)] = (out[(task, prp)][0], m.group(1).strip("'\""))
    return out


def matches_expected(expected, verdict, tag):
    want, sub = expected
    if want == "true":
        return verdict == "SUCCEEDED"
    if want == "false":
        if verdict != "FAILED":
            return False
        return sub is None or SUBPROPERTY_TAG.get(sub) == tag
    return False


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("c_tsv")
    ap.add_argument("rust_tsv")
    ap.add_argument("--deltas", required=True)
    ap.add_argument("--semantic-deltas", default=DEFAULT_SEMANTIC)
    ap.add_argument("--corpus", default=DEFAULT_CORPUS)
    a = ap.parse_args(argv)

    c = aggregate(read_tsv(a.c_tsv, COLUMNS))
    r = aggregate(read_tsv(a.rust_tsv, COLUMNS))
    deltas = read_tsv(a.deltas, DELTA_COLUMNS)
    known_sd = sd_ids(a.semantic_deltas)
    expected = load_expected(a.corpus)

    lines, failed = [], False

    def report(name, ok, detail):
        nonlocal failed
        failed = failed or not ok
        lines.append("%s: %s %s" % (name, "PASS" if ok else "FAIL", detail))

    # deltas
    bad_refs = [d for d in deltas if d["sd_ref"] not in known_sd]
    accepted = {(d["task"], d["prp"], d["gen"], d["field"], d["c_value"], d["rust_value"])
                for d in deltas if d["sd_ref"] in known_sd}
    report("deltas", not bad_refs,
           "(%d linhas, sd_ref inexistente: %s)" % (
               len(deltas), ", ".join(sorted({d["sd_ref"] for d in bad_refs})) or "nenhum"))

    # keys
    only_c, only_r = sorted(set(c) - set(r)), sorted(set(r) - set(c))
    report("keys", not only_c and not only_r,
           "(%d C, %d Rust, só C: %d, só Rust: %d)" % (len(c), len(r), len(only_c), len(only_r)))
    common = sorted(set(c) & set(r))

    def diverge(fields):
        bad, ok_acc = [], 0
        for key in common:
            for field in fields(key):
                cv, rv = c[key][field], r[key][field]
                if cv == rv:
                    continue
                if key + (field, cv, rv) in accepted:
                    ok_acc += 1
                else:
                    bad.append("%s %s %s %s: %r -> %r" % (key + (field, cv, rv)))
        return bad, ok_acc

    def detail(bad, acc):
        shown = "; ".join(bad[:5]) + ("; ..." if len(bad) > 5 else "")
        return "(%d divergências, %d aceitas)%s" % (len(bad) + acc, acc,
                                                   " " + shown if bad else "")

    bad, acc = diverge(lambda k: ["verdict"])
    report("verdict", not bad, detail(bad, acc))

    bad, acc = diverge(lambda k: ["tag", "line", "function"]
                       if c[k]["verdict"] == "FAILED" and r[k]["verdict"] == "FAILED" else [])
    report("failed-details", not bad, detail(bad, acc))

    bad, acc = diverge(lambda k: ["witness"]
                       if c[k]["witness"] == "1" and r[k]["witness"] != "1" else [])
    report("witness", not bad, detail(bad, acc))

    # expected
    gens = sorted({k[2] for k in set(c) | set(r)})
    exp_parts, exp_ok = [], True
    for g in gens:
        def hits(agg):
            return sum(1 for k, v in agg.items() if k[2] == g and (k[0], k[1]) in expected
                       and matches_expected(expected[(k[0], k[1])], v["verdict"], v["tag"]))
        hc, hr = hits(c), hits(r)
        exp_ok = exp_ok and hr >= hc
        exp_parts.append("%s %d->%d" % (g, hc, hr))
    report("expected", exp_ok, "(" + ", ".join(exp_parts) + ")")

    # desempenho
    def ratios(field):
        out = []
        for key in common:
            if c[key][field] > 0:
                out.append((r[key][field] / c[key][field], key))
        return out

    for field, name, limit in (("wall", "wall", WALL_MAX), ("rss", "rss", RSS_MAX)):
        rs = ratios(field)
        med = statistics.median(x for x, _ in rs) if rs else 1.0
        report(name, med <= limit + EPS, "(mediana %.3f, limite %.2f, %d chaves)" % (med, limit, len(rs)))
        for x, key in rs:
            if x > WARN_RATIO + EPS:
                lines.append("warning: %s %s %s razão %s %.2f > %.1f" % (key + (name, x, WARN_RATIO)))

    to_parts, to_ok = [], True
    for g in gens:
        tc = sum(1 for k, v in c.items() if k[2] == g and v["verdict"] == "TIMEOUT")
        tr = sum(1 for k, v in r.items() if k[2] == g and v["verdict"] == "TIMEOUT")
        to_ok = to_ok and tr <= tc
        to_parts.append("%s %d->%d" % (g, tc, tr))
    report("timeouts", to_ok, "(" + ", ".join(to_parts) + ")")

    for l in lines:
        print(l)
    print("gate: FAIL" if failed else "gate: PASS")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
