#!/bin/bash
# Exercises the real column and Quick Look with working, absent and broken PDF
# modules. bwrap masks only this child's QtQuick/Pdf directories; no host package
# is removed. The external-open stub records argv and launches no application.
set -eu
cd "$(dirname "$0")/.."
. "$PWD/tools/bachy-sandbox-guard"
for tool in qs bwrap python3; do command -v "$tool" >/dev/null || { echo "pdf-optional: missing $tool"; exit 1; }; done
sandbox_make "$FIXTURE_ROOT/pdf-optional-$$"
lab=$SANDBOX_PATH
trap 'sandbox_remove "$lab"' EXIT
mkdir -p "$lab"/{config,state,cache,data,runtime,fixture,broken}
chmod 700 "$lab/runtime"
cp -a ui "$lab/broken/ui"
printf 'import QtQuick\nItem { nonexistentProperty: true }\n' > "$lab/broken/ui/PreviewPdf.qml"
mkdir -p "$lab/config/js"
cp ui/js/*.js "$lab/config/js/"
sed 's|../ui/js/PreviewKeys.js|js/PreviewKeys.js|' tests/pdf-optional.qml > "$lab/config/shell.qml"
cat > "$lab/open-stub" <<'STUB'
#!/bin/bash
printf '%s\n' "$@" >> "$PDF_OPTIONAL_OPEN_LOG"
STUB
chmod +x "$lab/open-stub"
python3 - "$lab/fixture" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]);objects=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 300] /Resources << >> /Contents 5 0 R >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 300] /Resources << >> /Contents 5 0 R >>','<< /Length 0 >>\nstream\n\nendstream']
b=b'%PDF-1.4\n';offsets=[0]
for i,o in enumerate(objects,1):offsets.append(len(b));b+=f'{i} 0 obj\n{o}\nendobj\n'.encode()
x=len(b);b+=b'xref\n0 6\n0000000000 65535 f \n'
for n in offsets[1:]:b+=f'{n:010} 00000 n \n'.encode()
b+=f'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{x}\n%%EOF\n'.encode();(p/'sample.pdf').write_bytes(b);(p/'corrupt.pdf').write_text('not a PDF')
PY
export XDG_CONFIG_HOME="$lab/config" XDG_STATE_HOME="$lab/state" XDG_CACHE_HOME="$lab/cache" XDG_DATA_HOME="$lab/data" XDG_RUNTIME_DIR="$lab/runtime"
export QT_QPA_PLATFORM=offscreen QSG_RHI_BACKEND=software QT_QUICK_BACKEND=software BACHY_BIN="$lab/open-stub" PDF_OPTIONAL_FIXTURE="$lab/fixture"
# Cover system installations and an explicitly supplied developer runtime.
mask=()
IFS=: read -ra import_paths <<< "${QML_IMPORT_PATH:-}:${QML2_IMPORT_PATH:-}:/usr/lib/qt6/qml"
for path in "${import_paths[@]}"; do
    if [ -n "$path" ] && [ -d "$path/QtQuick/Pdf" ]; then mask+=(--tmpfs "$(readlink -f "$path/QtQuick/Pdf")"); fi
done
[ "${#mask[@]}" -gt 0 ] || { echo 'pdf-optional: provide a Qt runtime with QtQuick.Pdf for the installed-support control'; exit 1; }
for mode in present missing broken; do
    export PDF_OPTIONAL_MODE=$mode PDF_OPTIONAL_UI="$PWD/ui"
    [ "$mode" != broken ] || export PDF_OPTIONAL_UI="$lab/broken/ui"
    for surface in column quicklook; do
        export PDF_OPTIONAL_SURFACE=$surface PDF_OPTIONAL_OPEN_LOG="$lab/$mode-$surface.open"
        run=()
        [ "$mode" != missing ] || run=(bwrap --bind / / --die-with-parent "${mask[@]}")
        log="$lab/$mode-$surface.log"
        if ! timeout 20 "${run[@]}" qs -p "$lab/config" > "$log" 2>&1; then cat "$log"; exit 1; fi
        if grep -q 'PDFOPTIONAL FAIL' "$log" || ! grep -q 'PDFOPTIONAL DONE' "$log"; then cat "$log"; exit 1; fi
        grep 'PDFOPTIONAL' "$log"
        if [ "$mode" != present ]; then
            printf '%s\n' --open "$lab/fixture/sample.pdf" > "$lab/expected-open"
            cmp "$lab/expected-open" "$PDF_OPTIONAL_OPEN_LOG"
            echo "PASS $mode $surface opens the exact PDF through Bachy's opener"
        fi
    done
done
# Core startup must still work without the module, including the separate chooser.
export BACHY_BIN="$PWD/target/debug/bachy" BACHY_PATH="$lab/fixture"
export BACHY_PICKER='{"title":"PDF optional test","directory":false,"folder":"'"$lab/fixture"'"}'
export BACHY_PICKER_REPLY="$lab/picker-reply"
for entry in shell picker; do
    log="$lab/missing-$entry.log"
    set +e
    timeout 8 bwrap --bind / / --die-with-parent "${mask[@]}" qs -p "$PWD/ui/boot/$entry.qml" > "$log" 2>&1
    status=$?
    set -e
    if [ "$status" != 124 ] || ! grep -q 'Configuration Loaded' "$log" || grep -qiE 'ERROR|Failed to load configuration|could not load|window body did not load' "$log"; then
        cat "$log"; exit 1
    fi
    echo "PASS $entry starts and stays alive with QtQuick.Pdf hidden"
done
echo 'pdf-optional: six surface/runtime combinations and both entry points passed'
