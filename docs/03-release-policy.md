# Release And Supply Chain Policy

Each provider release must be reproducible, auditable, and locally consumable.

## Required Release Record

- Provider package name and semantic version.
- Upstream name, version, immutable source URL, and SHA-256.
- Complete license notices for upstream code and emitted artifacts.
- Toolchain versions and non-default build flags.
- All local patches with a stated purpose.
- Artifact SHA-256 values.
- Supported WASM/runtime/platform target matrix.
- WIT compatibility result and consumer conformance-test result.

## Trust Boundary

Providers are application dependencies. They may receive only the capabilities
that their WASI/component configuration declares. A native plugin or sidecar,
when that generic provider type is introduced, is trusted native code and must
be marked as such with platform-specific artifact hashes. Do not present native
code as sandboxed merely because its caller is WASM.
