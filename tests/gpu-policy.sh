#!/bin/bash
# Synthetic connectors and ICDs: never probes or changes a real GPU.
set -euo pipefail
cd "$(dirname "$0")/.."
. "$PWD/tools/bachy-sandbox-guard"
. "$PWD/tools/bachy-gpu-policy"
sandbox_make "$FIXTURE_ROOT/gpu-policy-$$"
lab=$SANDBOX_PATH
trap 'sandbox_remove "$lab"' EXIT
mkdir -p "$lab/drm/card0-eDP-1" "$lab/drm/card0/device" "$lab/drm/card1/device/power" "$lab/icd" "$lab/runtime"
printf 'connected\n' > "$lab/drm/card0-eDP-1/status"
printf '0x8086\n' > "$lab/drm/card0/device/vendor"
printf '0x10de\n' > "$lab/drm/card1/device/vendor"
printf 'active\n' > "$lab/drm/card1/device/power/runtime_status"
touch "$lab/icd/intel_icd.json" "$lab/icd/nvidia_icd.json"
cat > "$lab/check" <<'STUB'
#!/bin/bash
printf '%s\n' "$1" "$3" > "$2/called"
STUB
chmod +x "$lab/check"
unset QSG_RHI_BACKEND VK_DRIVER_FILES VK_ICD_FILENAMES DRI_PRIME __NV_PRIME_RENDER_OFFLOAD BACHY_VK_PIN
export XDG_RUNTIME_DIR="$lab/runtime" HYPRLAND_INSTANCE_SIGNATURE=test
state="$XDG_RUNTIME_DIR/bachy-gpu-test"
select_gpu() { bachy_select_gpu "$lab/binary" "$lab/check" "$1" "$lab/drm" "$lab/icd"; }
check() { if [ "$2" != "$3" ]; then echo "FAIL $1: expected [$2], got [$3]"; exit 1; fi; echo "PASS $1"; }
(
    select_gpu --gui
    check 'first launch pins Intel' "$lab/icd/intel_icd.json" "$VK_DRIVER_FILES"
    check 'both Vulkan loader variables agree' "$VK_DRIVER_FILES" "$VK_ICD_FILENAMES"
    check 'automatic pin is marked for external-app cleanup' 1 "$BACHY_VK_PIN"
    wait
)
check 'background helper receives the real binary and NVIDIA ICD' "$(printf '%s\n' "$lab/binary" "$lab/icd/nvidia_icd.json")" "$(cat "$state/called")"
printf '%s\n' "$lab/icd/nvidia_icd.json" > "$state/ready"
(
    select_gpu --pick
    check 'a later chooser uses ready awake NVIDIA' "$lab/icd/nvidia_icd.json" "$VK_DRIVER_FILES"
)
printf 'suspended\n' > "$lab/drm/card1/device/power/runtime_status"
touch "$state/failed"
(
    select_gpu --gui
    check 'suspended NVIDIA returns to Intel' "$lab/icd/intel_icd.json" "$VK_DRIVER_FILES"
    check 'stale readiness is removed' false "$([ -f "$state/ready" ] && echo true || echo false)"
)
rm "$state/called"
(
    select_gpu --gui
    wait
    check 'failure cooldown avoids another helper' false "$([ -f "$state/called" ] && echo true || echo false)"
)
for variable in QSG_RHI_BACKEND VK_DRIVER_FILES VK_ICD_FILENAMES DRI_PRIME __NV_PRIME_RENDER_OFFLOAD; do
    (
        export "$variable=operator-choice"
        select_gpu --gui
        check "explicit $variable preserved" operator-choice "${!variable}"
        check "explicit $variable skips automatic pin" '' "${BACHY_VK_PIN:-}"
    )
done
for mode in --backend --open --version --probe-vulkan; do
    (select_gpu "$mode"; check "$mode does not select a GPU" '' "${VK_DRIVER_FILES:-}")
done
mkdir -p "$lab/drm/card1-HDMI-A-1"
printf 'connected\n' > "$lab/drm/card1-HDMI-A-1/status"
(select_gpu --gui; check 'mixed display vendors keep the existing renderer policy' '' "${VK_DRIVER_FILES:-}")
echo 'gpu-policy: all checks passed'
