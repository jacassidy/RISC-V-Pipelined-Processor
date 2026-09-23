# EVOLVE.md: Evo runner maintenance guide

This clone is an Evo online runner for `RISC-V-Pipelined-Processor`
(Evo project `192d227b-7dca-4d60-98cf-92b0c690b877`, GitHub `jacassidy/RISC-V-Pipelined-Processor`, branch `main`).
It simulates the core with Verilator. Guide: https://app.velobyte.ai/agent.md. No credentials live in this file,
in `.evo/runner/`, or in any profile.

The repository has no agent instruction file (`CLAUDE.md`, `AGENTS.md`) to link this guide from. If one is added, link this file from it.

## Owner decisions

- 2026-09-23, owner: "I want to get this set up so I can use Verilator to simulate my GitHub project. (riscv core)"
  Target: Verilator simulation of this core on this computer (profile `rv-verilator`).
- 2026-09-23, owner: "clone to Documents". Clone location: `~/Documents/RISC-V-Pipelined-Processor`.
- 2026-09-23, RTL fix choice: "Keep the fix (Recommended)". `src/Packages/ZICSRType.pkg` enum width changed from
  `$clog2(CSR_COUNT)` to `$clog2(CSR_COUNT+1)`: RV64 has 8 CSRs plus the `dumby` terminator, which overflowed a 3-bit enum
  and made Verilator refuse to elaborate RV64. RV32 (11 CSRs + `dumby`, 4 bits) is unchanged.
- 2026-09-23, owner: "Commit and push and then I'll tell the agent to pull and give me a little blurb about how it should
  finish setting up or anything else it should talk to me about." The harness, this guide and the RTL fix were pushed to `main`.
- 2026-09-23, disk choice: "Clear old evo-lc3-rv64 cache (19 GB)". `/home` was 100% full; `~/.cache/evo-lc3-rv64` was deleted.

## Layout

| Path | Tracked | Purpose |
| --- | --- | --- |
| `.evo/runner/rv-sim.sh` | yes | Wrapper: `build`, `correctness`, `rv32-single`, `rv32-pipe`, `rv64-single`, `rv64-pipe`, `bench`, `lint`, `diag-toolchain`, `diag-host`, `identity` |
| `.evo/runner/rvsim.py` | yes | Simulation driver: writes a per-config `parameters.svh`, builds with Verilator, runs tests, prints results |
| `.evo/runner/tb/tb_evo.sv` | yes | Verilator testbench: `testingCore` + instruction/data memories, lockstep and done-store checking |
| `.evo/runner/profiles/rv-verilator.template.json` | yes | Secret-free profile template (`__CLONE__`, `__HOME__`, `__IDENTITY_SHA256__` placeholders) |
| `.evo/runner/render-profile.sh` | yes | Renders the template to `.evo/local/runner-profiles/rv-verilator.json` |
| `.evo/local/` | no (gitignored) | Resolved profile and local run evidence (`evidence/run-*.json`) |
| `.evo-build/` | no (gitignored) | Workspace tar and Verilator build dirs (`.evo-build/sim/<config>/`) |

## How the simulation works

- HEAD's top level is `testingCore` (memories external). The old `doubleMemoryCore` is commented out and
  `vectorStorage` was deleted in `8ca5f03`, so the Questa testbenches in `testing/Testbenches/` do not elaborate as-is.
  `tb_evo.sv` rebuilds the same memory model: combinational reads, synchronous byte-enabled writes, 4096 words each,
  zero-initialized. Timing matches the original testbenches: `clk` starts high with a 10-unit period, reset is released
  at t=12, and checks happen on each negedge.
- Configurations are made without editing the repo: `rvsim.py` copies `incdir/parameters.svh`, replaces the
  `PIPELINED` / `XLEN_32` / `XLEN_64` define lines, and puts that copy first on the include path. All other defines
  (`ZICSR`, `ZICNTR`, `ZIHPM`, `DEBUG_PRINT`) come from the repo file.
- Lockstep mode compares `dut.ComputeCore.Rd1_W` (the register-file write data) with the expected file, one vector per
  cycle. `xxxxxxxx` lines in expected files are don't-cares: `rvsim.py` splits each file into value and mask hex, since
  Verilator has no X state.
- Store mode (`full_program`) passes when the core stores `0x0F` to address `0xC`. It fails on a wrong value, on fetching
  an all-zero word (ran out of instructions) or after `MAX_CYCLES`.
- The harness (`rvsim.py`, `tb_evo.sv`) always runs from this clone. RTL, `incdir/` and `testing/TestCode/` come from the
  job workspace.

## Tests

| Test | Config | Program / expected | Result 2026-09-23 |
| --- | --- | --- | --- |
| `rv32-single/chronological` | RV32 single-cycle | `rv32i_chronological.hex` / `expected_rv32i_chronological.hex` | pass, 31 vectors, 32 cycles |
| `rv32-single/full_rv32i` | RV32 single-cycle | `full_RV32I.hex` / `expected_full_RV32I_outputs.hex` (28 of 29 are don't-care) | pass, 29 vectors |
| `rv32-single/full_program` | RV32 single-cycle | `full_program.hex`, done-store `0x0F` to `0xC` | pass, 87 cycles |
| `rv32-pipe/chronological` | RV32 5-stage | `rv32i_chronological.hex` / `expected_pipelined_rv32i_chronological.hex` | pass, 35 vectors, 36 cycles |
| `rv32-pipe/full_program` | RV32 5-stage | `full_program.hex` | pass, 137 cycles |
| `rv64-single/chronological` | RV64 single-cycle | `rv64i_chronological.hex` / `expected_rv64i_chronological.hex` | pass with known mismatch at vector 44 |
| `rv64-pipe/chronological` | RV64 5-stage | same program / `expected_pipelined_rv64i_chronological.hex` | pass with known mismatch at vector 49 |

Known mismatch (open, for the owner): in both RV64 configs the only failing vector is `ld x1, 0xc(x0)` right after
`sd x5, 0xc(x0)`, a misaligned doubleword access at `0xC`. The core aligns data addresses to 8 bytes; the load returns
`0x00000000000000EF` where the hand-written expectation is the full `x5` (`0xFFFFF6F00FFFFF6F`). That expected file
predates the load/store rework (`5737299`, `e628ad9`). `KNOWN_MISMATCHES` in `rvsim.py` lists exactly these vectors. A
known-mismatch test passes only if every vector runs and the mismatches are exactly that list, so a new mismatch fails,
and so does this one starting to match. When the RTL or the expected file is fixed, remove the entry in the same change.

Negative control, checked 2026-09-23: running the single-cycle RV32 binary against the pipelined expectations fails with
25 mismatches and a nonzero exit.

## Profile `rv-verilator`

- Contract `evolve_cli.external_profile.v1`, target `verilator-rv-pipelined`, architecture `x86_64`, `physical_risk: none`
  (software simulation only; no attached device).
- Identity: `rv-sim.sh identity` prints `{"identity": "<contents of /etc/machine-id>"}`; the profile pins the `sha256:` of that string.
  After an OS reinstall, `external probe` fails with `device_identity_mismatch`: re-render and reconfigure.
- Build: `rv-sim.sh build` in `{workspace}` tars the workspace (without `.git`, `.evo-build`, `.evo/local`, `testing/vsim/work`)
  to `.evo-build/workspace.tar`, the execute artifact.
- Execute: `rv-sim.sh <workload>`, one declared input `workload` in
  `{correctness, rv32-single, rv32-pipe, rv64-single, rv64-pipe, bench, lint}`, timeout 300 s. The job gets the artifact as
  `artifact-<digest>` in an empty directory; the wrapper unpacks it into `./ws` and builds there.
- Diagnostics: `toolchain` (Verilator, g++, Python, riscv64-unknown-elf-gcc versions) and `host` (CPU, memory, free disk).

## Workloads, outputs and units

| Workload | Output | Pass criterion |
| --- | --- | --- |
| `correctness` | stdout: one `PASS`/`FAIL <test> vectors= errors= cycles=` line per test, then `RVSIM_SUMMARY=<json>` (`rvsim.results.v1`); stderr: build times, mismatch lines | exit 0; every test passes as defined above |
| `rv32-single`, `rv32-pipe`, `rv64-single`, `rv64-pipe` | same format, only that config's tests | exit 0 |
| `bench` | stdout: one JSON object (`rvsim.bench.v1`), `metrics[]` of `{name, value, unit}`: `<config>.verilator_build` (s), `<test>.cycles` (cycles), `<test>.sim_wall` (s) | exit 0; also requires correctness |
| `lint` | stdout: `{"lint_errors", "lint_warnings", "by_code"}` from `verilator --lint-only -Wall` on `testingCore` (RV32 single-cycle repo defaults); stderr: the tail of the lint log | exit 0 and `lint_errors` 0 |

The test programs are tiny (30–140 cycles). `sim_wall` is milliseconds, mostly process startup: it measures the
harness, not the core. Cycle counts are exact and deterministic.

## Machine and tools (verified 2026-09-23)

| Tool | Path | Version |
| --- | --- | --- |
| Verilator | `/usr/bin/verilator` | 5.020 2024-01-01 (Debian 5.020-1) |
| g++ | `/usr/bin/g++` | 13.3.0 (Ubuntu 24.04) |
| Python | `/usr/bin/python3` | 3.12.3 (standard library only) |
| riscv64-unknown-elf-gcc | `/usr/bin/riscv64-unknown-elf-gcc` | 13.2.0 (used by `testing/TestCode/assemble*.sh`, not by the runner) |
| evolve / evo-runner | `~/.local/bin/` | evolve 0.2.0 |
| Host | velobyteDesktop | AMD Ryzen 7 5800X, 16 threads, 48 GB RAM |

Nothing was installed or upgraded for this setup.

## Setup and update commands

Every runner command for this project uses its own config dir, so the other Evo enrollment in `~/.config/evo-runner` (ga8) is untouched:

```sh
export EVO_RUNNER_CONFIG_DIR="$HOME/.config/evo-runner-rv-pipelined"
.evo/runner/render-profile.sh
evo-runner --json external validate --config .evo/local/runner-profiles/rv-verilator.json
evo-runner --json external configure --profile rv-verilator --config .evo/local/runner-profiles/rv-verilator.json --replace
evo-runner --json external doctor --profile rv-verilator
evo-runner --json external probe --profile rv-verilator
evolve runner start --project 192d227b-7dca-4d60-98cf-92b0c690b877 --profile rv-verilator --connect-only
evolve runner service install --dry-run
evolve runner service install
evolve runner service status
evolve fleet runners
```

Quick local simulation without Evo: `python3 .evo/runner/rvsim.py test all` (or a config such as `rv32-pipe`, or one test such as
`rv64-single/chronological`), `python3 .evo/runner/rvsim.py bench`, `python3 .evo/runner/rvsim.py lint`, `python3 .evo/runner/rvsim.py list`.

Local check through the profile, packing the working tree the way a job receives it:

```sh
E=.evo/local/evidence; mkdir -p $E/ws
git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C $E/ws
evo-runner --json pack-workspace --root $E/ws --output $E/ws.tar --max-bytes 67108864
echo '{"arguments":["correctness"],"repeats":1,"timeout_seconds":300}' > $E/wl.json
evo-runner --json external run --profile rv-verilator --artifact $E/ws.tar --workload $E/wl.json --diagnostic toolchain --diagnostic host
```

Workload JSON: declared inputs go in `arguments` by position; `repeats` is required. Stdout and stderr come back base64-encoded
in `result.payload.repeats[].stdout_base64`.

When tests, programs, expected files, configurations, outputs or toolchains change, update this file, `rvsim.py` (`TESTS`,
`KNOWN_MISMATCHES`, `CONFIGS`), the template and the wrapper in the same change. Then re-render, `validate`,
`configure --replace`, run the affected workload locally through the profile, restart with
`evolve runner service stop && evolve runner service start` once no job is active, and re-verify `evolve fleet runners`.
A new input choice needs the template, the `case` in `rv-sim.sh` and the table above.

## Service

- systemd user unit `evo-runner-608b004f9cac3f19.service` (`~/.config/systemd/user/`), runs `evo-runner serve` with
  `EVO_RUNNER_CONFIG_DIR=~/.config/evo-runner-rv-pipelined`. Job workspaces go in `~/.config/evo-runner-rv-pipelined/workspaces` (on `/home`).
- Runner/device id `03004524-1808-4dec-bb5f-ddfdb93a3108`, adapter `external`, profile `rv-verilator`.
- Operate: `evolve runner service status|stop|start|uninstall` with the same `EVO_RUNNER_CONFIG_DIR`. Uninstall keeps
  profiles and credentials; revoke the runner separately.
- Setup did not change linger or sleep settings.

## Verification record (2026-09-23)

- Source: `52d2dd9` plus the uncommitted `ZICSRType.pkg` fix and the uncommitted `.evo/` harness.
- Local through the profile (`external run`, packed working tree): `correctness` exit 0, all 7 tests pass (RV64 with the known
  mismatches), 10.5 s including four ~2.5 s Verilator builds. `bench` exit 0, 10.4 s. `lint` exit 0: 0 errors, 61 warnings
  (CASEX 20, UNUSEDSIGNAL 24, DECLFILENAME 16, VARHIDDEN 1). Diagnostics `toolchain` and `host` completed.
- `external validate`, `configure`, `doctor` (ready) and `probe` (`identity_verified: true`) passed.
- Enrollment `connected: true`; service `active/running`, 0 restarts; `evolve fleet runners` lists
  `03004524-1808-4dec-bb5f-ddfdb93a3108` as `online` on project `192d227b-…` with profile `rv-verilator`.
- Not yet verified: a cloud job sent to this runner (the build step on the hub path, output retrieval, cancellation,
  reconnection). That needs an `evolve fleet run`, which the owner has not requested. `.evo/setup.json`,
  `.evo/fleet.json` and the goal agreement (setup.md stages 1 and 3) have not been done. The harness and the RTL fix
  were pushed to `main` on 2026-09-23.

## Gotchas

- `/home` was 100% full during setup (fixed by deleting a 19 GB cache; 19 GB free afterwards). A full disk shows up as
  `ar: ... file truncated` / `ld: file too short` in the Verilator link step, not as an obvious ENOSPC.
- `testing/vsim/` holds Questa project files and waveform temp files (`wlft*`, `vsim.wlf`) that Verilator does not use.
- `DEBUG_PRINT` is on in `parameters.svh`; `_IStage` prints `[TB] ENTRY_ADDR`. `+ENTRY_ADDR=<hex>` sets the reset PC.
