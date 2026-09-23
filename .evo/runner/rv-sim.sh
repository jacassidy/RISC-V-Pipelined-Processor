#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${RVSIM_PYTHON:-/usr/bin/python3}"
export VERILATOR="${VERILATOR:-/usr/bin/verilator}"
export PATH="/usr/bin:/bin:${PATH:-}"

enter_workspace() {
  if [[ -f incdir/parameters.svh && -d src ]]; then
    return
  fi
  local art
  art="$(find . -maxdepth 1 -type f -name 'artifact-*' | head -1)"
  if [[ -z "$art" ]]; then
    echo "no workspace or artifact in $(pwd)" >&2
    exit 4
  fi
  mkdir -p ws
  tar -xf "$art" -C ws
  cd ws
}

sim() {
  enter_workspace
  export RVSIM_ROOT="$PWD"
  export RVSIM_BUILD="$PWD/.evo-build/sim"
  "$PY" "$HERE/rvsim.py" "$@"
}

case "${1:-}" in
  build)
    mkdir -p .evo-build
    tar --exclude=./.evo-build --exclude=./.git --exclude=./.evo/local --exclude=./testing/vsim/work --exclude='__pycache__' -cf .evo-build/workspace.tar .
    ;;
  correctness) sim test all ;;
  rv32-single|rv32-pipe|rv64-single|rv64-pipe) sim test "$1" ;;
  bench) sim bench all ;;
  lint) sim lint ;;
  diag-toolchain)
    "$VERILATOR" --version
    g++ --version | head -1
    "$PY" --version
    riscv64-unknown-elf-gcc --version 2>/dev/null | head -1 || echo "riscv64-unknown-elf-gcc: not found"
    ;;
  diag-host)
    echo "cpus=$(nproc) $(grep -m1 'model name' /proc/cpuinfo)"
    free -m | sed -n 1,2p
    df -h . | tail -1
    ;;
  identity)
    id="$(cat /etc/machine-id)"
    printf '{"identity":"%s"}\n' "$id"
    ;;
  *)
    echo "usage: rv-sim.sh build|correctness|rv32-single|rv32-pipe|rv64-single|rv64-pipe|bench|lint|diag-toolchain|diag-host|identity" >&2
    exit 2
    ;;
esac
