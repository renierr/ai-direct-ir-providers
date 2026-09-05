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

## Environment

### Consume A Released Provider

An application vendors a reviewed provider package and consumes its released
component artifact through `air`. It does not need Rust, Cargo, an upstream
library checkout, or a provider build toolchain. A Core WAT application needs
only `air`, which embeds WAT assembly and validation. A component project
that composes local providers may additionally need a composition tool on its
build machine; see the open decision below. A prebuilt component needs only
`air` to check, run, and distribute.

### Develop A Provider

Provider development needs the exact upstream compiler/runtime toolchain named
in that provider's `provenance.toml`, plus Git and `wasm-tools 1.257.1`. Do not
assume one universal language toolchain: an adapter may require Rust/Cargo, C,
or another upstream-supported build path. Record every required version and
command in `provenance.toml` before releasing an artifact.

Use `wasm-tools` only for the Component Model contract and artifact checks:

| Command | Provider use |
|---|---|
| `wasm-tools validate` | Validate the released Core WASM or Component binary. |
| `wasm-tools component wit` | Parse and validate the public WIT package. |
| `wasm-tools component targets` | Verify that the artifact conforms to its declared WIT world. |

Composition of a consumer root with prebuilt provider components is an open
decision in `ai-direct-ir`: `wasm-tools compose` is deprecated upstream, and the
component text format cannot embed a prebuilt `.wasm`. A provider package is not
blocked by it — publish the artifact, its WIT world, and its conformance test.

`wasm-tools` is the Apache-2.0 Bytecode Alliance CLI, the same license this
repository uses, subject to retaining its notices. We do not bundle its platform-specific executable in a provider
package or application distribution. It is a build-time tool; released provider
packages contain their component artifact, checksums, provenance, and notices.

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

Repository-authored material is licensed under Apache-2.0 (`LICENSE`,
`NOTICE`). The catalog is deliberately permissive: a provider is vendored into
a consuming application, so a copyleft catalog would set the license of every
application that adopts one. The `ai-direct-ir` harness stays AGPL-3.0-or-later;
it is a host that an application runs under, not code an application links in.

Provider artifacts retain the licenses of their upstream dependencies. Each
package must carry complete notices in `providers/<name>/licenses/`, and an
upstream license incompatible with Apache-2.0 redistribution is grounds to
reject the candidate.
