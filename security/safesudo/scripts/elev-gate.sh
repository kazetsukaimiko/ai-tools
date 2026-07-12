#!/usr/bin/env bash
# elev-gate.sh — thin launcher; policy lives in elev-gate.py for portability.
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
exec python3 "$DIR/elev-gate.py"
