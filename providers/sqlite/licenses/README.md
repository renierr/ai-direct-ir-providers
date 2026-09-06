# Licenses

Add complete notices for the provider adapter, upstream source, and every
dependency included in released artifacts.

The adapter code written in this repository is Apache-2.0, matching the catalog
(`LICENSE`, `NOTICE`). `provider.toml`'s `license` field is the SPDX expression
for the *released artifact*, which combines the adapter with its upstream
material — here `Apache-2.0 AND (MIT OR Apache-2.0)` for SQLite (public
domain) plus `rusqlite`/`libsqlite3-sys` (`MIT OR Apache-2.0`). Record the
upstream terms here verbatim at release; do not summarize them.

Release checklist: SQLite blessing (public domain, from the amalgamation),
`rusqlite` + `libsqlite3-sys` MIT/Apache-2.0 texts, and every dependency
the released `.wasm` actually contains (derive from `adapter/Cargo.lock`).
