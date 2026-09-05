#!/usr/bin/env bash
# Conformance: hash stdin through the provider and compare with sha256sum.
# The sizes cover the padding boundaries where SHA-256 implementations break:
# a tail of 56 or more needs a second block.
set -uo pipefail
cd "$(dirname "$0")"

AIR=${AIR:-air}
command -v "$AIR" >/dev/null || { echo "air not on PATH; set AIR=<path>" >&2; exit 2; }

pass=0 fail=0
for n in 0 1 3 55 56 57 63 64 65 119 120 127 128 1000 65536; do
  data=$(head -c "$n" /dev/urandom | base64 | head -c "$n")
  got=$(printf '%s' "$data" | "$AIR" run host.toml 2>/dev/null)
  want=$(printf '%s' "$data" | sha256sum | cut -d' ' -f1)
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL length %s\n  got  %s\n  want %s\n' "$n" "$got" "$want"
  fi
done

# The standard's own vector, so the test does not only compare against
# another implementation.
got=$(printf 'abc' | "$AIR" run host.toml 2>/dev/null)
want=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
if [ "$got" = "$want" ]; then pass=$((pass + 1)); else
  fail=$((fail + 1)); printf 'FAIL FIPS 180-4 "abc"\n  got  %s\n  want %s\n' "$got" "$want"
fi

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
