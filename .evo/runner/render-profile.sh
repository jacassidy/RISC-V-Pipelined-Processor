#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-rv-verilator}"
CLONE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ID="$(bash "$CLONE/.evo/runner/rv-sim.sh" identity | python3 -c 'import json,sys;print(json.load(sys.stdin)["identity"],end="")')"
SHA="sha256:$(printf '%s' "$ID" | sha256sum | cut -d' ' -f1)"
OUT="$CLONE/.evo/local/runner-profiles/$NAME.json"
mkdir -p "$(dirname "$OUT")"
sed -e "s#__CLONE__#$CLONE#g" -e "s#__HOME__#$HOME#g" -e "s#__IDENTITY_SHA256__#$SHA#g" "$CLONE/.evo/runner/profiles/$NAME.template.json" > "$OUT"
echo "$OUT"
