# AGENTS.md -- ai-direct:sqlite

## Rules

- The SQL engine is upstream's. Do not reimplement SQLite here, and do not
  patch `rusqlite`/`libsqlite3-sys`. If a change is needed, change the
  adapter or raise it upstream.
- `adapter/src/lib.rs` is the canonical ABI boundary and is ABI: the WIT
  package, interface, and version must match `wit/sqlite.wit`, or
  `wit-bindgen` fails the build. Renaming any of them is a contract change.
- This component is `std` and imports `wasi:filesystem`, `wasi:clocks`,
  `wasi:random/insecure-seed`, and the `wasi:cli` command world by design —
  the deliberate exception to the pure providers' import-nothing contract.
  Do not let it import anything else (no sockets): check
  `wasm-tools component wit` output on every rebuild and keep
  `provider.toml [requirements]` exact.
- Handles are `u32`s for one run because resources cannot cross the
  provider boundary. Exposing a real `resource connection` is a contract
  change requiring harness composition support, not an adapter edit.
- One statement per `exec`. Multi-statement or streaming cursors are a
  contract change, not an implementation detail.
- Re-run `./build.sh` and `tests/run.sh` after any change, and update
  `provider.toml`, `checksums.txt`, and `provenance.toml` when the artifact
  moves. An artifact whose hash is not recorded is not released.
- Do not add this package to `registry/index.toml` until the release
  checklist in README.md is complete.
- Never install, upgrade, or remove software without explicit user consent.
- Never commit or push without an explicit request.
