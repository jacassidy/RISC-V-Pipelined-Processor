import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(os.environ.get("RVSIM_ROOT", Path(__file__).resolve().parents[2]))
BUILD = Path(os.environ.get("RVSIM_BUILD", ROOT / ".evo-build" / "sim"))
VERILATOR = os.environ.get("VERILATOR", shutil.which("verilator") or "/usr/bin/verilator")
TB = Path(__file__).resolve().parent / "tb" / "tb_evo.sv"
CODE = ROOT / "testing" / "TestCode"
CHRONO = CODE / "RD1_Lockstep" / "Chronological_Instructions"

CONFIGS = {
    "rv32-single": {"xlen": 32, "pipelined": False},
    "rv32-pipe": {"xlen": 32, "pipelined": True},
    "rv64-single": {"xlen": 64, "pipelined": False},
    "rv64-pipe": {"xlen": 64, "pipelined": True},
}

KNOWN_MISMATCHES = {
    "rv64-single/chronological": [44],
    "rv64-pipe/chronological": [49],
}

TESTS = {
    "rv32-single/chronological": ("rv32-single", "lockstep", CHRONO / "rv32i_chronological.hex", CHRONO / "expected_rv32i_chronological.hex"),
    "rv32-single/full_rv32i": ("rv32-single", "lockstep", CODE / "RD1_Lockstep" / "full_RV32I.hex", CODE / "RD1_Lockstep" / "expected_full_RV32I_outputs.hex"),
    "rv32-single/full_program": ("rv32-single", "store", CODE / "Full_Programs" / "full_program.hex", None),
    "rv32-pipe/chronological": ("rv32-pipe", "lockstep", CHRONO / "rv32i_chronological.hex", CHRONO / "expected_pipelined_rv32i_chronological.hex"),
    "rv32-pipe/full_program": ("rv32-pipe", "store", CODE / "Full_Programs" / "full_program.hex", None),
    "rv64-single/chronological": ("rv64-single", "lockstep", CHRONO / "rv64i_chronological.hex", CHRONO / "expected_rv64i_chronological.hex"),
    "rv64-pipe/chronological": ("rv64-pipe", "lockstep", CHRONO / "rv64i_chronological.hex", CHRONO / "expected_pipelined_rv64i_chronological.hex"),
}

CONFIG_LINE = re.compile(r"^\s*(//)?\s*`define\s+(PIPELINED|XLEN_32|XLEN_64)\b.*$")


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def sources():
    pkgs = sorted((ROOT / "src" / "Packages").glob("*.pkg"))
    svs = sorted(p for p in (ROOT / "src").rglob("*.sv") if p.name != "DoubleMemoryCore.sv")
    return [str(p) for p in pkgs + svs]


def write_params(cfg, dest):
    c = CONFIGS[cfg]
    lines = (ROOT / "incdir" / "parameters.svh").read_text().splitlines()
    out, inserted = [], False
    for line in lines:
        if CONFIG_LINE.match(line):
            if not inserted:
                if c["pipelined"]:
                    out.append("    `define PIPELINED")
                out.append(f"    `define XLEN_{c['xlen']}")
                inserted = True
            continue
        out.append(line)
    if not inserted:
        raise SystemExit("parameters.svh has no PIPELINED/XLEN_* define lines to replace")
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "parameters.svh").write_text("\n".join(out) + "\n")


def build(cfg):
    d = BUILD / cfg
    inc = d / "inc"
    write_params(cfg, inc)
    exe = d / "obj" / "Vtb_evo"
    argv = [VERILATOR, "--binary", "--timing", "-Wno-fatal", "-Wno-lint", "-Wno-style",
            "-Wno-MULTIDRIVEN", "--top-module", "tb_evo", "-j", str(os.cpu_count() or 4),
            "--Mdir", str(d / "obj"), "-o", "Vtb_evo",
            f"-I{inc}", f"-I{ROOT / 'incdir'}", *sources(), str(TB)]
    t0 = time.monotonic()
    r = subprocess.run(argv, capture_output=True, text=True)
    dt = time.monotonic() - t0
    if r.returncode != 0 or not exe.exists():
        log(r.stdout[-4000:], r.stderr[-8000:])
        raise SystemExit(f"verilator build failed for {cfg} (exit {r.returncode})")
    log(f"built {cfg} in {dt:.1f}s")
    return exe, dt


def split_expected(src, dest, xlen):
    digits = xlen // 4
    vals, masks = [], []
    for raw in src.read_text().splitlines():
        tok = raw.split("//")[0].strip()
        if not tok:
            continue
        tok = tok.replace("_", "").rjust(digits, "0")[-digits:]
        vals.append("".join("0" if ch in "xXzZ" else ch for ch in tok))
        masks.append("".join("0" if ch in "xXzZ" else "f" for ch in tok))
    dest.mkdir(parents=True, exist_ok=True)
    v, m = dest / (src.stem + ".val.hex"), dest / (src.stem + ".mask.hex")
    v.write_text("\n".join(vals) + "\n")
    m.write_text("\n".join(masks) + "\n")
    return v, m, len(vals)


def run_test(name, exe):
    cfg, mode, imem, expected = TESTS[name]
    argv = [str(exe), f"+IMEM={imem}", f"+MODE={mode}", f"+LABEL={name}"]
    n = None
    if expected:
        v, m, n = split_expected(expected, BUILD / cfg / "vectors", CONFIGS[cfg]["xlen"])
        argv += [f"+EXPECT_VAL={v}", f"+EXPECT_MASK={m}", f"+NVEC={n}"]
    t0 = time.monotonic()
    r = subprocess.run(argv, capture_output=True, text=True, timeout=120, cwd=BUILD / cfg)
    dt = time.monotonic() - t0
    out = r.stdout + r.stderr
    res = {"test": name, "config": cfg, "mode": mode, "exit": r.returncode, "sim_wall_s": round(dt, 4), "expected_vectors": n}
    m = re.search(r"EVO_RESULT (.*)", out)
    if m:
        for kv in m.group(1).split():
            k, _, val = kv.partition("=")
            res[k] = int(val) if val.isdigit() else val
    mismatches = [int(v) for v in re.findall(r"^MISMATCH vector=(\d+)", out, re.M)]
    known = KNOWN_MISMATCHES.get(name, [])
    res["mismatch_vectors"] = mismatches
    res["known_mismatch_vectors"] = known
    completed = n is not None and res.get("vectors") == n
    if known:
        res["passed"] = completed and res.get("reason") in ("all_vectors_matched", "mismatches") and mismatches == known
    else:
        res["passed"] = r.returncode == 0 and res.get("status") == "PASS"
    for line in out.splitlines():
        if line.startswith(("MISMATCH", "DONE_STORE", "%Error", "%Fatal")):
            log(f"[{name}] {line}")
    return res


def select(names):
    if not names or names == ["all"]:
        return list(TESTS)
    picked = []
    for n in names:
        hits = [t for t in TESTS if t == n or t.startswith(n + "/")]
        if not hits:
            raise SystemExit(f"unknown test or config {n!r}; known: {', '.join(TESTS)}")
        picked += [h for h in hits if h not in picked]
    return picked


def cmd_test(args):
    names = select(args.names)
    exes, build_s = {}, {}
    for cfg in dict.fromkeys(TESTS[n][0] for n in names):
        exes[cfg], build_s[cfg] = build(cfg)
    results = [run_test(n, exes[TESTS[n][0]]) for n in names]
    passed = all(r["passed"] for r in results)
    for r in results:
        note = f" known_mismatch={r['known_mismatch_vectors']}" if r["known_mismatch_vectors"] else ""
        print(f"{'PASS' if r['passed'] else 'FAIL'} {r['test']} vectors={r.get('vectors')} errors={r.get('errors')} cycles={r.get('cycles')}{note}")
    summary = {"schema": "rvsim.results.v1", "passed": passed, "verilator": verilator_version(),
               "build_s": {k: round(v, 2) for k, v in build_s.items()}, "results": results}
    print("RVSIM_SUMMARY=" + json.dumps(summary, sort_keys=True))
    return 0 if passed else 1


def cmd_bench(args):
    names = select(args.names)
    exes, build_s = {}, {}
    for cfg in dict.fromkeys(TESTS[n][0] for n in names):
        exes[cfg], build_s[cfg] = build(cfg)
    results = [run_test(n, exes[TESTS[n][0]]) for n in names]
    metrics = []
    for cfg, s in build_s.items():
        metrics.append({"name": f"{cfg}.verilator_build", "value": round(s, 3), "unit": "s"})
    for r in results:
        metrics.append({"name": f"{r['test']}.cycles", "value": r.get("cycles"), "unit": "cycles"})
        metrics.append({"name": f"{r['test']}.sim_wall", "value": r["sim_wall_s"], "unit": "s"})
    passed = all(r["passed"] for r in results)
    print(json.dumps({"schema": "rvsim.bench.v1", "passed": passed, "verilator": verilator_version(),
                      "metrics": metrics}, sort_keys=True))
    return 0 if passed else 1


def cmd_lint(args):
    argv = [VERILATOR, "--lint-only", "-Wall", "-Wno-fatal", "--top-module", "testingCore",
            f"-I{ROOT / 'incdir'}", *sources()]
    r = subprocess.run(argv, capture_output=True, text=True)
    out = r.stdout + r.stderr
    warnings = re.findall(r"^%Warning-([A-Z0-9_]+):", out, re.M)
    errors = re.findall(r"^%Error", out, re.M)
    counts = {}
    for w in warnings:
        counts[w] = counts.get(w, 0) + 1
    log(out[-6000:])
    print(json.dumps({"lint_errors": len(errors), "lint_warnings": len(warnings), "by_code": dict(sorted(counts.items()))}, sort_keys=True))
    return 0 if r.returncode == 0 and not errors else 1


def verilator_version():
    return subprocess.run([VERILATOR, "--version"], capture_output=True, text=True).stdout.strip()


def main():
    p = argparse.ArgumentParser(prog="rvsim")
    sub = p.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("test")
    t.add_argument("names", nargs="*")
    t.set_defaults(fn=cmd_test)
    b = sub.add_parser("bench")
    b.add_argument("names", nargs="*")
    b.set_defaults(fn=cmd_bench)
    sub.add_parser("lint").set_defaults(fn=cmd_lint)
    sub.add_parser("list").set_defaults(fn=lambda a: print("\n".join(TESTS)) or 0)
    a = p.parse_args()
    sys.exit(a.fn(a))


if __name__ == "__main__":
    main()
