#!/usr/bin/env bash
# Conformance: measure text through the provider and compare with a known
# table. The cases cover the four ways a column count differs from a byte
# count -- multi-byte but narrow, wide, zero-width, and styled -- because a
# width function that only handles ASCII passes nothing else.
set -uo pipefail
cd "$(dirname "$0")"

AIR=${AIR:-air}
command -v "$AIR" >/dev/null || { echo "air not on PATH; set AIR=<path>" >&2; exit 2; }

pass=0 fail=0
check() {
  local want=$1 text=$2 what=$3
  local got
  got=$(printf '%s' "$text" | "$AIR" run host.toml 2>/dev/null)
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n  got  %s\n  want %s\n' "$what" "$got" "$want"
  fi
}

check 0  ''              'empty'
check 5  'hello'         'ascii'
check 4  'café'          'multi-byte, one column each'
check 6  '日本語'         'wide: three ideographs, two columns each'
check 2  $'a̐e'     'combining mark takes no column'
check 2  '🙂'            'emoji is wide'
check 15 $'\x1b[1;36m◆ Project setup\x1b[0m' 'ANSI CSI takes no column'
check 3  $'\x1b[0mabc'   'style at the start'
check 3  $'abc\x1b[0m'   'style at the end'
check 0  $'\x1b[1;36m\x1b[0m' 'style only'

# An independent reference for the east-asian cases, so the table is not only
# compared against the implementation that produced it.
if python3 -c 'import unicodedata' 2>/dev/null; then
  for text in 'hello' 'café' '日本語' '🙂'; do
    want=$(python3 - "$text" <<'PY'
import sys, unicodedata
text = sys.argv[1]
total = 0
for ch in text:
    if unicodedata.combining(ch):
        continue
    total += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
print(total)
PY
)
    check "$want" "$text" "unicodedata cross-check: $text"
  done
else
  printf 'note: python3 unavailable, skipped the unicodedata cross-check\n'
fi

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
