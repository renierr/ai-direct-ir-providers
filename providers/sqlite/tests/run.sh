#!/usr/bin/env bash
# Conformance: round-trip one row through the provider, then verify the
# database file with the native sqlite3 CLI. A fresh data dir per run:
# the consumer creates the table, so a leftover DB would fail the CREATE.
set -euo pipefail
cd "$(dirname "$0")"

AIR=${AIR:-air}
command -v "$AIR" >/dev/null || { echo "air not on PATH; set AIR=<path>" >&2; exit 2; }
command -v sqlite3 >/dev/null || { echo "sqlite3 not on PATH" >&2; exit 2; }

rm -rf data
mkdir -p data

got=$("$AIR" run host.toml 2>/dev/null)
[ "$got" = "OK" ] || { printf 'FAIL consumer said: %s\n' "$got"; exit 1; }

want=42
got=$(sqlite3 data/test.db "SELECT v FROM kv;")
[ "$got" = "$want" ] || { printf 'FAIL sqlite3 said %s, want %s\n' "$got" "$want"; exit 1; }

# The file persists beyond the run: reopen read-only and check again.
got=$(sqlite3 data/test.db "SELECT k FROM kv;")
[ "$got" = "hello" ] || { printf 'FAIL k column said %s\n' "$got"; exit 1; }

printf 'sqlite conformance passed\n'
