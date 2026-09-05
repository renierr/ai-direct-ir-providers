# AGENTS.md -- ai-direct:text-width

## Rules

- The Unicode tables are upstream's. Do not reimplement UAX #11 here, and do
  not patch `unicode-width`. If a width is wrong, raise it upstream; if the
  ANSI handling is wrong, that is the adapter's and belongs here.
- `adapter/src/lib.rs` is the canonical ABI boundary and is ABI: the export
  name carries the interface and version
  (`ai-direct:text-width/width@0.1.0#columns`). Renaming the WIT package,
  interface, or version means renaming it too, or `wasm-tools component embed`
  fails to find the export.
- The component must keep importing nothing. `no_std` with `panic = "abort"`
  is what keeps it free of WASI, and a pure provider is far easier to audit and
  to vendor. Adding an import is a contract change, not an implementation
  detail.
- The 512-byte measuring window and the 64 KiB heap are contract, not
  implementation: both are documented limits in README.md. Changing either
  means changing that section.
- Re-run `./build.sh` and `tests/run.sh` after any change, and update
  `provider.toml`, `checksums.txt`, and `provenance.toml` when the artifact
  moves. An artifact whose hash is not recorded is not released.
- Never install, upgrade, or remove software without explicit user consent.
- Never commit or push without an explicit request.
