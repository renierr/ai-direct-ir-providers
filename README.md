# AI-Direct IR Providers

Curated, reproducible provider packages for
[AI-Direct IR](https://github.com/renierr/ai-direct-ir). The harness loads,
links, validates, and packages applications; this repository makes established
libraries practical for applications authored directly as WebAssembly.

This is not a replacement for crates.io, npm, PyPI, Maven, vcpkg, or upstream
projects. Those remain the sources of libraries. A provider package adapts a
specific upstream release into an AI-friendly WebAssembly interface and records
how to reproduce and audit the result.

This is a builder-phase catalog. Its package layout, metadata, and WIT worlds
are deliberately replaceable while the companion harness adopts Component Model
composition. Do not add migration or compatibility machinery until a provider
has real consumers and an explicit release commitment.

## Three Repositories

| Repository | What it is for | What we do there |
|---|---|---|
| `ai-direct-ir` | Generic platform | Build the harness that composes, validates, runs, and packages applications. |
| `ai-direct-ir-providers` | This catalog | Turn selected upstream libraries into reusable, auditable WASM/WIT provider packages. |
| `ai-direct-ir-example-mail` | Integration-driving app | Builds a real WAT mail client and exposes concrete provider needs. |

When the mail app needs SQLite, SMTP, storage, or terminal functionality, this
repository provides the reusable adapter and contract. Do not add the library
to the harness or turn the catalog into a copy of a general package registry.

```text
upstream library
  -> reproducible provider build + small adapter
  -> WIT contract + WASM component/artifact
  -> pinned provider package
  -> application vendors and composes it locally
```

## What Belongs Here

- WIT interfaces and versioned provider metadata.
- Reproducible build instructions, source URLs, source hashes, and patches.
- License notices for every shipped artifact and its upstream dependencies.
- Checksums, compatibility information, and executable conformance tests.
- Small, focused adapters for mature libraries such as SQLite, JSON, codecs,
  cryptography, and HTTP tooling.

Do not add an unpinned dependency, an opaque binary without provenance, or a
general copy of an upstream package registry.

## Provider Package

Each provider lives at `providers/<name>/` and starts from
`templates/provider/`:

```text
providers/<name>/
  provider.toml        package metadata and artifact list
  wit/                 public WIT interfaces
  provenance.toml      upstream source and reproducible build record
  licenses/            provider and upstream license notices
  tests/               conformance tests and fixtures
  artifacts/           released, checksummed WASM artifacts
  README.md            AI-facing API and use instructions
```

`artifacts/` is ignored while building. A reviewed release explicitly force-adds
only the artifacts named in `provider.toml`, together with their SHA-256 hashes.

## How Applications Use Providers

An application does not fetch a provider at runtime. It selects a version,
vendors the package into its own repository, and locks its hash:

```text
notes-app/
  host.toml
  notes.wat
  vendor/
    ai-direct-sqlite-1.0.0/
      provider.toml
      artifacts/wasm32-wasi/sqlite.component.wasm
      checksums.txt
```

The current harness supports direct Core WASM composition via `[[libs]]` and
`[[bridges]]`. The Component Model target will consume a provider's WIT world
and component artifact directly. See `docs/02-consumption.md`.

## Start A Provider

Copy the template, rename its valid `example` WIT package/interface/world and
replace every other `__PLACEHOLDER__`, then follow its checklist:

```bash
cp -R templates/provider providers/example
```

The command is intentionally only a starting point. Do not publish or consume
the copied template as a dependency.

## Status

The repository currently establishes the package contract. The first proof
provider should be small and dependency-free (for example SHA-256); SQLite is
the first planned stateful provider after WIT/component composition is proven.

## License

Repository-authored material is licensed under AGPL-3.0-or-later. Provider
artifacts retain the licenses of their upstream dependencies; each package must
include complete notices in `licenses/`.
