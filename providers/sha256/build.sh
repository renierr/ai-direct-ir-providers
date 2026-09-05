#!/usr/bin/env bash
# Rebuild the released component from the adapter source. Requires the
# toolchain pinned in provenance.toml plus wasm-tools; installs nothing.
set -euo pipefail
cd "$(dirname "$0")"

CORE=adapter/target/wasm32-wasip1/release/sha256_provider.wasm
OUT=artifacts/wasm32-wasi/sha256.component.wasm

cargo build --manifest-path adapter/Cargo.toml --release \
  --target wasm32-wasip1 --offline

# `wit-bindgen` is not needed: the adapter already exports the canonical ABI
# shape the world requires, so embedding the type section is enough to lift it.
wasm-tools component embed wit "$CORE" -o adapter/embedded.wasm \
  --world sha256-provider
wasm-tools component new adapter/embedded.wasm -o "$OUT"
wasm-tools validate --features all "$OUT"

sha256sum "$OUT" | sed "s| .*| $(basename "$OUT")|" > checksums.txt
printf 'built %s\n' "$OUT"
sha256sum "$OUT"
