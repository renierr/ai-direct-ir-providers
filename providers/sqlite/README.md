# ai-direct:sqlite

SQLite embedded database for AI-Direct IR applications, backed by the
SQLite amalgamation through the [`rusqlite`](https://crates.io/crates/rusqlite)
crate. The SQL engine is upstream's; this package supplies the WIT contract,
the adapter, the reproducible build, and the conformance test.

> **Status: built, unregistered.** Artifact is hashed in `provider.toml` /
> `checksums.txt`, but there is no `registry/index.toml` entry until a
> consumer proves it (completion gate).

## Interface

```wit
package ai-direct:sqlite@0.1.0;

interface store {
  variant value {
    int-val(s64), real-val(float64), text-val(string),
    blob-val(list<u8>), null-val,
  }
  record row { values: list<value> }
  record result-set { columns: list<string>, rows: list<row> }

  open: func(path: string) -> result<u32, string>;
  exec: func(handle: u32, sql: string, params: list<value>)
    -> result<result-set, string>;
  close: func(handle: u32) -> result<_, string>;
}
```

Connections are `u32` handles, not resources: handles cannot cross the
provider boundary, so the provider maps them to live connections for the
duration of one run. One call = one statement; no multi-statement or
streaming cursor yet — that is a contract change when an app needs it.

## Use It

The database file must sit under a granted directory, writable for writes:

```toml
[[providers]]
path = "vendor/ai-direct-sqlite-0.1.0/artifacts/wasm32-wasi/sqlite.component.wasm"

[[dirs]]
path = "data"
write = true
```

```wat
(import "ai-direct:sqlite/store@0.1.0" (instance $s
  (export "open" (func (param "path" string) (result (result u32 string))))))
```

`tests/consumer.wat` is a complete working example: open, create, insert
with bound params, select, check, close.

## Permissions And Limits

The component is `std` and imports `wasi:filesystem`, `wasi:clocks`,
`wasi:random/insecure-seed`, and the `wasi:cli` command world — the
deliberate counterpart to the pure providers' import-nothing contract
(SQLite needs a clock and randomness internally; the `cli` half is Rust
`std` startup). It shares the application's preopened directories and
nothing else: a path outside the grants fails, and without `write = true`
any write fails. It never touches sockets or the network. Recheck with
`wasm-tools component wit` on every rebuild and keep `provider.toml
[requirements]` exact.

- Single statement per `exec`; `?` placeholders bind positionally.
- Handles live for one run; an unknown handle is an error string.
- Errors come back as `err(string)` — SQLite messages verbatim.

## Build And Verify

```bash
./build.sh                       # adapter -> component
AIR=/path/to/air ./tests/run.sh  # conformance against sqlite3 CLI
```

`build.sh` installs nothing. It needs the toolchain pinned in
`provenance.toml`: Rust with the `wasm32-wasip2` target, `wit-bindgen`
(via crates.io, locked in `adapter/Cargo.lock`), and `wasm-tools`.
The `cargo build` output is already a component, so unlike the pure
providers there is no `component embed/new` lift — only validation.

## Release

1. `./build.sh` succeeds; record exact crate versions + hashes from
   `adapter/Cargo.lock` into `provenance.toml` (replace `PENDING`).
2. Fill `provider.toml`'s `sha256` from `checksums.txt` (replace
   `UNRELEASED`); add upstream notices under `licenses/`.
3. `AIR=... ./tests/run.sh` passes; `wasm-tools validate` passes.
4. Only then add the `registry/index.toml` entry with `wasi = ["filesystem"]`.

## Licenses

The adapter, WIT, and package metadata are Apache-2.0 (this repository).
SQLite is public domain; `rusqlite`/`libsqlite3-sys` are `MIT OR
Apache-2.0`. Their notices go in `licenses/` at release; the released
artifact contains compiled upstream code, so those notices travel with it.
