# __NAME__ Provider

Rename the template's WIT package, interface, and world from `example` before
release. `ai-direct:__NAME__@0.1.0` adapts `__UPSTREAM_NAME__` for AI-Direct IR.

## Interface

The public contract is `wit/__NAME__.wit`. Document each operation, ownership
rule, errors, required capabilities, and a consumer example before release.

## Build

Follow `provenance.toml` exactly. Do not replace its pinned upstream source or
toolchain with an unrecorded local version.

## Release Checklist

- Replace all placeholders.
- Add upstream notices under `licenses/`.
- Build and hash every declared artifact.
- Validate WIT and WASM/component artifacts.
- Add a consumer conformance test.
