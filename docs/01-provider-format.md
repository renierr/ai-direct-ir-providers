# Provider Format

A provider package is a pinned adaptation of an upstream library for
AI-Direct IR applications. It supplies a stable application-facing interface,
not a generic mirror of the source ecosystem.

## Required Files

```text
providers/<name>/
  provider.toml
  README.md
  AGENTS.md
  wit/<interface>.wit
  provenance.toml
  licenses/
  tests/
  artifacts/
```

`provider.toml` identifies the package version, WIT world, artifacts, hashes,
supported targets, and required capabilities. `provenance.toml` identifies the
exact upstream release, source hash, toolchain, commands, and patch series.

## Interface Rule

Use WIT as the public provider interface. A WIT package name is versioned:

```wit
package ai-direct:example@1.0.0;
```

Prefer application operations, typed `result` values, and resources over raw
upstream FFI. A SQLite provider should expose database connections and queries,
not every SQLite C symbol.

## Artifact Rule

An artifact must be either:

- a Core WASM module usable by the current `[[libs]]`/`[[bridges]]` path; or
- a WASM component implementing the package WIT world for the Component Model
  path.

Record target, file path, SHA-256, and validation command. Do not publish an
artifact that cannot be rebuilt from its provenance record.
