# ai-direct:sha256

SHA-256 digests for AI-Direct IR applications, backed by the RustCrypto
[`sha2`](https://crates.io/crates/sha2) crate. The cryptography is upstream's;
this package supplies the WIT contract, the canonical ABI adapter, the
reproducible build, and the conformance test.

## Interface

```wit
package ai-direct:sha256@0.1.0;

interface digest {
  hash: func(data: list<u8>) -> list<u8>;      // 32 raw bytes
  hash-hex: func(data: list<u8>) -> string;    // 64 lowercase hex characters
}
```

## Use It

Declare the artifact in your manifest and import the interface like any other:

```toml
[[providers]]
path = "vendor/ai-direct-sha256-0.1.0/artifacts/wasm32-wasi/sha256.component.wasm"
```

```wat
(import "ai-direct:sha256/digest@0.1.0" (instance $d
  (export "hash-hex" (func (param "data" (list u8)) (result string)))))
(alias export $d "hash-hex" (func $hash-hex))
(core func $hash-hex-l
  (canon lower (func $hash-hex) (memory $memory) (realloc $realloc)))
```

`air` instantiates the provider and forwards its exports into your imports. No
composition tool is involved. `tests/consumer.wat` is a complete working
example.

## Permissions And Limits

The component imports **nothing** — no WASI, no host capability, no ambient
authority. It is a pure function of its input, so it cannot read a file, open a
socket, or observe a clock.

- Input is bounded by the memory the component can grow into; the adapter grows
  linear memory on demand and never frees, so one instance's peak input governs
  its footprint.
- One-shot only: there is no streaming or incremental digest yet. An
  application that hashes something larger than it wants resident needs a
  `hash-stream` resource, which is a contract change.
- `hash` and `hash-hex` each hash the input independently. Call one.

## Build And Verify

```bash
./build.sh                       # adapter -> core wasm -> component
AIR=/path/to/air ./tests/run.sh  # conformance against sha256sum
```

`build.sh` installs nothing. It needs the toolchain pinned in
`provenance.toml`: Rust with the `wasm32-wasip1` target, and `wasm-tools`.

`wit-bindgen` is deliberately not required. The adapter exports the canonical
ABI shape the world already implies — `hash(ptr, len) -> retptr` plus
`cabi_realloc` — so `wasm-tools component embed` and `component new` are enough
to lift the core module into a component.

## Conformance

`tests/run.sh` hashes stdin through the component and compares against
coreutils `sha256sum` at 0, 1, 3, 55, 56, 57, 63, 64, 65, 119, 120, 127, 128,
1000 and 65536 bytes — the padding boundaries where a tail of 56 or more forces
a second block — plus the FIPS 180-4 `"abc"` vector.

## Licenses

The adapter, WIT, and package metadata are Apache-2.0 (this repository).
`sha2` and its dependencies are `MIT OR Apache-2.0`; their notices are in
`licenses/`. The released artifact contains compiled upstream code, so those
notices travel with it.
