#!/bin/bash
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
guard="$repo/tools/bachy-sandbox-guard"
BACHY_FIXTURE_ROOT=/tmp/bachy-metadata-fixtures
. "$guard"
sandbox_make "$FIXTURE_ROOT/run-$$"
left=$SANDBOX_PATH
BACHY_FIXTURE_ROOT=/dev/shm/bachy-metadata-fixtures
. "$guard"
sandbox_make "$FIXTURE_ROOT/run-$$"
right=$SANDBOX_PATH
cleanup() {
  BACHY_FIXTURE_ROOT=/tmp/bachy-metadata-fixtures
  . "$guard"
  sandbox_remove "$left"
  BACHY_FIXTURE_ROOT=/dev/shm/bachy-metadata-fixtures
  . "$guard"
  sandbox_remove "$right"
}
trap cleanup EXIT
python3 "$repo/tests/copy-metadata.py" "$left" "$right"
