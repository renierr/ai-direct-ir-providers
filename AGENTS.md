# AGENTS.md -- AI-Direct IR Providers

## Goal

This repository turns proven upstream libraries into reproducible, versioned
WebAssembly provider packages for AI-Direct IR applications. It is a curated
compatibility layer, not a replacement package registry and not a place to
reimplement mature libraries in WAT.

## Repository Role

This is the reusable dependency layer between upstream ecosystems and
AI-authored applications. `ai-direct-ir` owns generic runtime/composition work;
this repository owns provider contracts, artifacts, provenance, licenses, and
tests; `ai-direct-ir-example-mail` is an integration-driving consumer. When an
example exposes a general need, coordinate the change across the relevant
repositories and let the example break during the builder-phase redesign.

## Rules

- Never install, upgrade, or remove software without explicit user consent.
- **Never commit or push without an explicit request.** Finishing a unit of
  work is not a request. Leave changes in the working tree, report what
  changed, and let the user decide when it lands.
- Prefer upstream libraries and official source releases; record exact version,
  URL, source SHA-256, build command, tool versions, and every local patch in
  `provenance.toml`.
- Every provider needs a small public WIT interface. Do not expose a large raw
  C ABI when an application-oriented interface can be defined. A WIT directory
  is one package: give each contract its own `wit/` directory or
  `wasm-tools component wit` will reject the set.
- This repository is Apache-2.0 (`LICENSE`, `NOTICE`) while the harness and the
  example stay AGPL-3.0-or-later. Providers are vendored into consuming
  applications, so the catalog must not decide their license. Reject an upstream
  whose license is incompatible with Apache-2.0 redistribution.
- This is builder phase: redesign package metadata and WIT worlds directly when
  needed. Do not add compatibility or migration machinery until a provider has
  real consumers and an explicit release commitment.
- Keep generated build output ignored. A release artifact is committed only
  when `provider.toml`, `checksums.txt`, provenance, licenses, and executable
  tests identify and verify it.
- Do not copy upstream source trees into this repository by default. Use pinned
  source metadata and reproducible acquisition/build instructions. Vendor only
  when upstream licensing, availability, or reproducibility makes it necessary.
- Do not add an application-specific host API. A provider must be usable by any
  compatible app without changing `air`.
- Treat companion example applications as integration drivers. When one exposes
  a generic provider or Component Model need, evolve this catalog and the
  harness with it; the example may break during the builder-phase redesign.
- Before selecting an upstream implementation for SQLite, a database, or any
  other consequential provider, present the user with the candidate projects,
  licenses, WASM/component build path, maintenance/security tradeoffs, and a
  recommendation. Do not choose or vendor one without explicit approval.
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
