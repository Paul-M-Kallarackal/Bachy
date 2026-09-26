#!/usr/bin/env bash
# tests/thumbs.sh with the pre-linked worker off, so every video takes the exec path it replaced; see AGENTS.md "Thumbnail worker".
BACHY_THUMB_WORKER=off exec "$(dirname "$0")/thumbs.sh"
