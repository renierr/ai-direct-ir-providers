# Consuming Providers

Providers are selected during development, vendored into the application, and
bundled by the application distribution. They are never fetched at runtime.

## Current Core WASM Path

The current `air` runtime composes Core WASM modules through `host.toml`:

```toml
[[libs]]
path = "vendor/example/artifacts/core/example.wasm"
as = "example"
```

The application imports `example.*`; `air check` instantiates the complete
declared graph and proves imports, exports, and WASM types resolve.

Use `[[bridges]]` only when a provider owns its memory and matches the current
copying bridge call shape. The Core path is useful for direct WAT and small,
low-level interfaces.

## Component Model Path

The planned Component Model target will resolve the provider's WIT package and
world. It will compose compatible components and map declared WASI permissions
to the application bundle. WIT is the durable public API; Core ABI wrappers are
implementation details or transitional adapters.

## From Ecosystems To Providers

1. Choose an upstream library from crates.io, npm, PyPI, SQLite upstream, or
   another ecosystem.
2. Check whether it already ships a compatible WASM component.
3. If not, build it to WASM and add a focused WIT adapter.
4. Record exact source/version/hash/licenses and test the resulting provider.
5. Vendor the released package into an application and pin its artifact hash.

The application sees the provider WIT contract, not the source ecosystem's
package manager or native ABI.
