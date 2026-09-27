#!/bin/bash
# Exercise actual playback plus absent/broken imports without removing host packages.
set -eu
cd "$(dirname "$0")/.."
. "$PWD/tools/bachy-sandbox-guard"
for tool in qs bwrap python3 ffmpeg; do command -v "$tool" >/dev/null || { echo "media-optional: missing $tool"; exit 1; }; done
sandbox_make "$FIXTURE_ROOT/media-optional-$$"
lab=$SANDBOX_PATH
trap 'sandbox_remove "$lab"' EXIT
mkdir -p "$lab"/{config,state,cache,data,runtime,broken}
chmod 700 "$lab/runtime"
cp -a ui "$lab/broken/ui"
printf 'import QtQuick\nItem { nonexistentProperty: true }\n' > "$lab/broken/ui/PreviewMedia.qml"
mkdir -p "$lab/config/js"
cp ui/js/*.js "$lab/config/js/"
sed 's|../ui/js/PreviewKeys.js|js/PreviewKeys.js|' tests/media-optional.qml > "$lab/config/shell.qml"
cat > "$lab/open-stub" <<'STUB'
#!/bin/bash
printf '%s\n' "$@" >> "$MEDIA_OPTIONAL_OPEN_LOG"
STUB
chmod +x "$lab/open-stub"
# Silent samples never send sound to the user's speakers.
ffmpeg -hide_banner -loglevel error -f lavfi -i anullsrc=r=8000:cl=mono -t 4 "$lab/sample.wav"
ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=blue:s=64x64:r=10 -t 4 -c:v mpeg4 "$lab/sample.mp4"
printf 'not audio' > "$lab/sample.wav.corrupt"
printf 'not video' > "$lab/sample.mp4.corrupt"
export XDG_CONFIG_HOME="$lab/config" XDG_STATE_HOME="$lab/state" XDG_CACHE_HOME="$lab/cache" XDG_DATA_HOME="$lab/data" XDG_RUNTIME_DIR="$lab/runtime"
export QT_QPA_PLATFORM=offscreen QSG_RHI_BACKEND=software QT_QUICK_BACKEND=software BACHY_BIN="$lab/open-stub"
mask=()
IFS=: read -ra import_paths <<< "${QML_IMPORT_PATH:-}:${QML2_IMPORT_PATH:-}:/usr/lib/qt6/qml"
for path in "${import_paths[@]}"; do
    if [ -n "$path" ] && [ -d "$path/QtMultimedia" ]; then mask+=(--tmpfs "$(readlink -f "$path/QtMultimedia")"); fi
done
[ "${#mask[@]}" -gt 0 ] || { echo 'media-optional: provide QtMultimedia for the installed-support control'; exit 1; }
for mode in present missing broken; do
    export MEDIA_OPTIONAL_MODE=$mode MEDIA_OPTIONAL_UI="$PWD/ui"
    [ "$mode" != broken ] || export MEDIA_OPTIONAL_UI="$lab/broken/ui"
    for surface in column quicklook; do
        for kind in audio video; do
            export MEDIA_OPTIONAL_SURFACE=$surface MEDIA_OPTIONAL_KIND=$kind MEDIA_OPTIONAL_OPEN_LOG="$lab/$mode-$surface-$kind.open"
            export MEDIA_OPTIONAL_FIXTURE="$lab/sample.wav"
            [ "$kind" != video ] || export MEDIA_OPTIONAL_FIXTURE="$lab/sample.mp4"
            run=()
            [ "$mode" != missing ] || run=(bwrap --bind / / --die-with-parent "${mask[@]}")
            log="$lab/$mode-$surface-$kind.log"
            if ! timeout 20 "${run[@]}" qs -p "$lab/config" > "$log" 2>&1; then cat "$log"; exit 1; fi
            if grep -q 'MEDIAOPTIONAL FAIL' "$log" || ! grep -q 'MEDIAOPTIONAL DONE' "$log"; then cat "$log"; exit 1; fi
            grep 'MEDIAOPTIONAL' "$log"
            if [ "$mode" != present ]; then
                printf '%s\n' --open "$MEDIA_OPTIONAL_FIXTURE" > "$lab/expected-open"
                cmp "$lab/expected-open" "$MEDIA_OPTIONAL_OPEN_LOG"
            fi
        done
    done
done
echo 'media-optional: twelve surface/runtime/kind combinations passed'
