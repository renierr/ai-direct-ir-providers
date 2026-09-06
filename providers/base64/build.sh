#!/usr/bin/env bash
# Assemble this self-contained WAT provider. No compiler, adapter or upstream
# package is involved; wasm-tools is used only for component validation.
set -euo pipefail
cd "$(dirname "$0")"

OUT=artifacts/wasm32-wasi/base64.component.wasm
wasm-tools parse base64.wat -o "$OUT"
wasm-tools validate --features all "$OUT"
sha256sum "$OUT" > checksums.txt
printf 'built %s\n' "$OUT"
