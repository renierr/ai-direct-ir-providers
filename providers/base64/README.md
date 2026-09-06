# ai-direct:base64

Pure WAT provider for padded RFC 4648 Base64 encoding. It imports no WASI or
host interface, has no upstream code dependency, and is useful for MIME text
parts, basic authentication values, tokens, and data transport.

```wit
interface codec {
  encode: func(text: string) -> string;
}
```

Build with `./build.sh`. The conformance consumer is exercised by the harness
test suite after installing this released package through `air add`.
