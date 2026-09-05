# AGENTS.md -- ai-direct:sha256

## Rules

- The cryptography is upstream's. Do not reimplement SHA-256 here, and do not
  patch `sha2`. If a change is needed, change the adapter or raise it upstream.
- `adapter/src/lib.rs` is the canonical ABI boundary and is ABI: the export
  names carry the interface and version (`ai-direct:sha256/digest@0.1.0#hash`).
  Renaming the WIT package, interface, or version means renaming them too, or
  `wasm-tools component embed` fails to find the export.
- The component must keep importing nothing. `no_std` with `panic = "abort"` is
  what keeps it free of WASI, and a pure provider is far easier to audit and to
  vendor. Adding an import is a contract change, not an implementation detail.
- Re-run `./build.sh` and `tests/run.sh` after any change, and update
  `provider.toml`, `checksums.txt`, and `provenance.toml` when the artifact
  moves. An artifact whose hash is not recorded is not released.
- Never install, upgrade, or remove software without explicit user consent.
- Never commit or push without an explicit request.
