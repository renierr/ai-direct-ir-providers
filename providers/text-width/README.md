# ai-direct:text-width

Terminal display widths for AI-Direct IR applications, backed by the
unicode-rs [`unicode-width`](https://crates.io/crates/unicode-width) crate.
The Unicode tables are upstream's; this package supplies the WIT contract, the
ANSI-aware adapter, the reproducible build, and the conformance test.

## Interface

```wit
package ai-direct:text-width@0.1.0;

interface width {
  columns: func(text: string) -> u32;
}
```

A column count is not a byte count and not a scalar count. `café` is five
bytes, four scalars and four columns; `日本語` is nine bytes, three scalars and
six columns; a combining mark is one scalar and no columns. A renderer that
centers or aligns text needs the third number, and it is the only one it
cannot compute itself.

ANSI CSI escape sequences consume bytes and no columns, so a caller may pass a
styled label and get the width the terminal will actually use. That is what
makes the interface usable by a program that has already decided how to colour
its own output.

## Use It

Declare the artifact in your manifest and import the interface like any other:

```toml
[[providers]]
path = "vendor/ai-direct-text-width-0.1.0/artifacts/wasm32-wasi/text-width.component.wasm"
```

```wat
(import "ai-direct:text-width/width@0.1.0" (instance $w
  (export "columns" (func (param "text" string) (result u32)))))
(alias export $w "columns" (func $columns))
(core func $columns-l
  (canon lower (func $columns) (memory $memory) (realloc $realloc)))
```

`u32` is a flat result, so unlike a `string` this call needs no return area.
`air` instantiates the provider and forwards its exports into your imports; no
composition tool is involved. `tests/consumer.wat` is a complete working
example.

## Permissions And Limits

The component imports **nothing** -- no WASI, no host capability, no ambient
authority. It is a pure function of its input, so it cannot read a file, open a
socket, or observe a clock.

- Input is bounded by a 64 KiB bump heap that never frees. One instance answers
  one call at a time and the harness drops it afterwards, so that is the peak
  footprint, not a running total.
- Widths are measured in 512-byte pieces, always split on a character
  boundary. A scalar is never divided; the one thing a split can lose is an
  emoji sequence that straddles the boundary, which no terminal label of that
  length contains.
- Only CSI sequences (`ESC [` ... final byte in `0x40..=0x7e`) are recognised
  as zero-width. Other escapes -- OSC, DCS -- are measured as their literal
  characters.
- Ambiguous-width characters follow the upstream default: narrow. A terminal
  configured otherwise will disagree, and that is a display setting no library
  can read.

## Build And Verify

```bash
./build.sh                       # adapter -> core wasm -> component
AIR=/path/to/air ./tests/run.sh  # conformance against a known table
```

`build.sh` installs nothing. It needs the toolchain pinned in
`provenance.toml`: Rust with the `wasm32-wasip1` target, and `wasm-tools`.

`wit-bindgen` is deliberately not required. The adapter exports the canonical
ABI shape the world already implies -- `columns(ptr, len) -> u32` plus
`cabi_realloc` -- so `wasm-tools component embed` and `component new` are
enough to lift the core module into a component.

## Conformance

`tests/run.sh` measures ten cases covering the four ways a column count
differs from a byte count -- multi-byte but narrow, wide, zero-width, and
styled -- and cross-checks the east-asian cases against Python's `unicodedata`
so the table is not compared only against the implementation that produced it.

## Licenses

The adapter, WIT, and package metadata are Apache-2.0 (this repository).
`unicode-width` is `MIT OR Apache-2.0`; its notices are in `licenses/`. The
released artifact contains compiled upstream code, so those notices travel
with it.
