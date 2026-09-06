#!/usr/bin/env bash
# Rebuild the released component from the adapter source. Requires the
# toolchain pinned in provenance.toml; installs nothing.
#
# The bundled SQLite C needs a WASI sysroot: set WASI_SDK explicitly, or
# let the probe below find wasi-sdk 34.0 user-locally (preferred) or in
# /opt. Unlike the pure providers, the output of `cargo build --target
# wasm32-wasip2` is already a component (WASI imports included), so no
# `wasm-tools component embed/new` lift is needed — only validation.
set -euo pipefail
cd "$(dirname "$0")"

OUT=artifacts/wasm32-wasi/sqlite.component.wasm

if [ -z "${WASI_SDK:-}" ]; then
  for candidate in \
    "$HOME/.local/share/wasi-sdk-34.0-x86_64-linux" \
    /opt/wasi-sdk-34.0-x86_64-linux /opt/wasi-sdk; do
    if [ -x "$candidate/bin/clang" ]; then WASI_SDK="$candidate"; break; fi
  done
fi
if [ -z "${WASI_SDK:-}" ] || [ ! -x "$WASI_SDK/bin/clang" ]; then
  echo "wasi-sdk clang not found; set WASI_SDK=<sdk-root>" >&2
  exit 2
fi

# Dashes are invalid in `export` names, so pass these through `env`.
# shellcheck disable=SC2086
env "CC_wasm32-wasip2=$WASI_SDK/bin/clang" \
  "CFLAGS_wasm32-wasip2=--sysroot=$WASI_SDK/share/wasi-sysroot" \
  cargo build --manifest-path adapter/Cargo.toml --release \
  --target wasm32-wasip2 --locked
cp "adapter/target/wasm32-wasip2/release/sqlite_provider.wasm" "$OUT"
wasm-tools validate --features all "$OUT"
wasm-tools component wit "$OUT" | head -25

sha256sum "$OUT" > checksums.txt
printf 'built %s\n' "$OUT"
sha256sum "$OUT"
