#!/usr/bin/env bash
# Exercise direct CLI argv, completion, failure, and overlap using real QML Process instances.
set -eu
QS_BIN=$(command -v qs)
. "$(dirname "$0")/../tools/bachy-sandbox-guard"
cd "$(dirname "$0")/.."
test_root="$FIXTURE_ROOT/bachy-taildrop-send-$$"
sandbox_make "$test_root"
trap 'sandbox_remove "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/config" "$test_root/home"
ln -s "$PWD/ui/Taildrop.qml" "$test_root/config/Taildrop.qml"
ln -s "$PWD/ui/js" "$test_root/config/js"
ln -s "$PWD/tests/taildrop-send.qml" "$test_root/config/shell.qml"
cat > "$test_root/bin/tailscale" <<'STUB'
#!/bin/sh
[ "$#" -eq 5 ] && [ "$1" = file ] && [ "$2" = cp ] && [ "$3" = -- ] && [ "$5" = laptop.example: ] || exit 64
case "$4" in
    '/tmp/a file.txt') sleep 0.1; exit 0 ;;
    '/tmp/failure file.txt') exit 42 ;;
    *) exit 65 ;;
esac
STUB
chmod +x "$test_root/bin/tailscale"
output=$(env HOME="$test_root/home" PATH="$test_root/bin:/usr/bin:/bin" QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 timeout 6 "$QS_BIN" -p "$test_root/config" 2>&1 || true)
if [[ "$output" != *'TAILDROP PASS argv success failure overlap'* || "$output" == *'TAILDROP FAIL'* ]]; then
    printf '%s\n' "$output"
    exit 1
fi
printf 'taildrop-send: argv, completion, failure and overlap passed\n'
