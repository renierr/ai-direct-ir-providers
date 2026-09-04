# AGENTS.md -- AI-Direct IR Providers

## Goal

This repository turns proven upstream libraries into reproducible, versioned
WebAssembly provider packages for AI-Direct IR applications. It is a curated
compatibility layer, not a replacement package registry and not a place to
reimplement mature libraries in WAT.

## Rules

- Never install, upgrade, or remove software without explicit user consent.
- Prefer upstream libraries and official source releases; record exact version,
  URL, source SHA-256, build command, tool versions, and every local patch in
  `provenance.toml`.
- Every provider needs a small public WIT interface. Do not expose a large raw
  C ABI when an application-oriented interface can be defined.
- Keep WIT APIs additive and versioned. Run `wasm-tools component semver-check`
  before publishing an evolved WIT world when the relevant artifacts exist.
- Keep generated build output ignored. A release artifact is committed only
  when `provider.toml`, `checksums.txt`, provenance, licenses, and executable
  tests identify and verify it.
- Do not copy upstream source trees into this repository by default. Use pinned
  source metadata and reproducible acquisition/build instructions. Vendor only
  when upstream licensing, availability, or reproducibility makes it necessary.
- Do not add an application-specific host API. A provider must be usable by any
  compatible app without changing `host-rs`.
- Verify claims by execution: validate WIT, validate component/artifact,
  exercise conformance tests, and record target/runtime limitations.

## Layout

- `providers/<name>/` -- one versioned provider package per directory.
- `templates/provider/` -- required package-file skeleton.
- `registry/index.toml` -- reviewed provider catalog index; metadata only.
- `docs/` -- provider format, consumption, release and security policy.

## Provider Completion Gate

1. Upstream provenance and licenses are complete.
2. WIT interface and compatibility policy are documented.
3. Artifact target, SHA-256, and build recipe are pinned.
4. `wasm-tools validate` and applicable component checks pass.
5. A consumer example proves the advertised interface.
6. The package explains required WASI permissions and platform limits.
