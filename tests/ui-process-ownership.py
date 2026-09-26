#!/usr/bin/env python3
"""Run the native harness's real teardown functions against a private fake /proc."""
import os
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


source = Path(__file__).with_name("ui.sh").read_text()
if os.geteuid() == Path("/").stat().st_uid:
    raise SystemExit("Run as the desktop user to exercise the foreign-uid boundary")


def function(name):
    start = source.index("\n" + name + "() {") + 1
    end = source.index("\n}", start) + 2
    return source[start:end]


root = Path(tempfile.mkdtemp(prefix="bachy-process-ownership-", dir="/tmp")).resolve()
(root / ".bachy-test-sandbox").write_text("private process guard fixtures\n")


def guard(path):
    assert str(path) and path.is_absolute() and path.is_relative_to(root), path
    assert (root / ".bachy-test-sandbox").is_file(), root


def process(pid, command, own=True, readable=True):
    path = root / "proc" / str(pid)
    guard(path)
    path.mkdir(parents=True)
    (path / "cmdline").write_bytes(command.encode() + b"\0")
    if readable:
        tag = str(root) if own else str(root / "foreign")
        (path / "environ").write_bytes(
            f"BACHY_TEST_RUN_ROOT={tag}\0BACHY_BIN=/bin/bachy-check\0BACHY_PATH={root}/fixture/listing\0".encode()
        )


process(123, "qs -p /candidate/ui")
process(124, "qs -p /candidate/ui", own=False)
process(126, "qs -p /candidate/ui", readable=False)
process(234, "/bin/bachy-check --backend", own=False)
process(235, "/bin/bachy-check --backend")
process(236, "/bin/bachy-check --backend", readable=False)
process(345, "gio monitor trash:///", own=False)
process(346, "gio monitor trash:///")
process(347, "gio monitor trash:///", readable=False)
helpers = "\n".join(function(name) for name in (
    "bachy_pids", "bachy_pid", "bachy_process_owned", "backend_pids", "owned_trash_monitors",
    "kill_bachy", "cleanup", "window_box", "click_row"
))
prelude = f"""
set -u -o pipefail
run_root={shlex.quote(str(root))}
fixture_root="$run_root/fixture"
thumb_fixture="$run_root/thumb"
hash_fixture="$run_root/hash"
stale_fixture="$run_root/stale"
bachy_ui=/candidate/ui
bachy_bin=/bin/bachy-check
bachy_window_class=local.bachy.FileManager
foreign_pids=""
qs_pids=""
backend_ids=234
monitor_ids=345
drain_wait_s=1
stuck=false
bachy_process_dir() {{ printf '%s/proc/%s\\n' "$run_root" "$1"; }}
pgrep() {{
    case "$2" in qs) value="$qs_pids" ;; bachy) value="$backend_ids" ;; gio) value="$monitor_ids" ;; *) return 2 ;; esac
    [[ -n "$value" ]] || return 1
    printf '%s\\n' "$value"
}}
kill() {{ printf 'SIMULATED_SIGNAL %s\\n' "$1"; "$stuck" || qs_pids=""; return 0; }}
sleep() {{ :; }}
fail() {{ printf 'FAIL %s\\n' "$*" >&2; exit 1; }}
hyprctl() {{ printf '%s\\n' "$client_payload"; }}
ipc() {{ printf '10 20\\n'; }}
omarchy-drive() {{ printf 'SIMULATED_CLICK %s\\n' "$*" >&2; }}
sandbox_remove() {{ printf 'SIMULATED_DELETE %s\\n' "$1"; }}
cache_restore() {{ :; }}
"""
cases = [
    ("owned window; foreign backend/monitor ignored", "qs_pids=123; kill_bachy", 0, "SIMULATED_SIGNAL 123", "FAIL"),
    ("foreign window refused", "qs_pids=124; kill_bachy", 1, "refusing to signal", "SIMULATED_SIGNAL"),
    ("vanished window harmless", "qs_pids=125; kill_bachy", 0, "", "SIMULATED_SIGNAL"),
    ("vanished identity explicit", "bachy_process_owned 125", 2, "", "SIMULATED_SIGNAL"),
    ("unreadable window refused", "qs_pids=126; kill_bachy", 1, "refusing to signal", "SIMULATED_SIGNAL"),
    ("stuck window bounded; fixtures kept", "qs_pids=123; stuck=true; drain_wait_s=0; cleanup", 1, "active fixture roots kept", "SIMULATED_DELETE"),
    ("foreign refusal keeps fixtures", "qs_pids=124; cleanup", 1, "active fixture roots kept", "SIMULATED_DELETE"),
    ("owned backend must drain", "backend_ids=235; cleanup", 1, "backend or Trash monitor survived", "SIMULATED_DELETE"),
    ("unreadable backend keeps fixtures", "backend_ids=236; cleanup", 1, "cannot inspect backend ownership", "SIMULATED_DELETE"),
    ("owned monitor must drain", "monitor_ids=346; cleanup", 1, "backend or Trash monitor survived", "SIMULATED_DELETE"),
    ("unreadable monitor keeps fixtures", "monitor_ids=347; cleanup", 1, "cannot inspect Trash monitor ownership", "SIMULATED_DELETE"),
    ("enumeration failure keeps fixtures", "pgrep() { return 2; }; cleanup", 1, "cannot enumerate", "SIMULATED_DELETE"),
    ("successful drain permits fixture cleanup", "qs_pids=123; cleanup", 0, "SIMULATED_DELETE", "FAIL"),
]
cases.append(("foreign uid refused", "bachy_process_dir() { printf '/\\n'; }; bachy_process_owned 123", 1, "", "SIMULATED_SIGNAL"))
owned_window = dict(pid=123, **{"class": "local.bachy.FileManager"}, at=[12, 42], size=[880, 620])
foreign_window = dict(owned_window, pid=124)
for name, windows, code in (
    ("owned pointer target", [owned_window], 0),
    ("ambiguous pointer targets refused", [owned_window, foreign_window], 1),
    ("foreign pointer target refused", [foreign_window], 1),
    ("vanished pointer target refused", [], 1),
    ("invalid pointer geometry refused", [dict(owned_window, size=[0, 620])], 1),
):
    body = "qs_pids=123; client_payload=" + shlex.quote(json.dumps(windows)) + "; click_row 0"
    cases.append((name, body, code, "SIMULATED_CLICK click 22 62" if code == 0 else "FAIL",
                  "FAIL" if code == 0 else "SIMULATED_CLICK"))
try:
    for name, body, code, present, absent in cases:
        result = subprocess.run(["bash"], input=prelude + helpers + "\n" + body + "\n", text=True, capture_output=True, timeout=5)
        output = result.stdout + result.stderr
        assert result.returncode == code and present in output and absent not in output, (name, result.returncode, output)
        print("PASS " + name)
    print(f"{len(cases)} process ownership checks, 0 failed; no real signals")
finally:
    for child in root.iterdir():
        if child.name == ".bachy-test-sandbox":
            continue
        guard(child)
        shutil.rmtree(child) if child.is_dir() else child.unlink()
    guard(root)
    (root / ".bachy-test-sandbox").unlink()
    root.rmdir()
