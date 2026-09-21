#!/bin/bash
set -Eeuo pipefail

AVD_NAME="AndroidWhatsApp"
AVD_PACKAGE="system-images;android-34;google_apis;x86_64"
DISPLAY_NUM=":0"

export HOME=/data
export ANDROID_USER_HOME=/data/.android
export ANDROID_AVD_HOME=/data/.android/avd
export DISPLAY="${DISPLAY_NUM}"

log() {
    echo "[AndroidWhatsApp] $*"
}

fatal() {
    echo "[AndroidWhatsApp] FATAL: $*" >&2
    exit 1
}

cleanup() {
    log "Shutting down..."
    for pid in "${SCRCPY_PID:-}" "${EMU_PID:-}" "${NOVNC_PID:-}" "${VNC_PID:-}" "${XVFB_PID:-}"; do
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            kill "${pid}" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT TERM INT

echo "============================================================"
echo " AndroidWhatsApp 0.2.3 - Headless Android + scrcpy"
echo "============================================================"
log "Kernel: $(uname -a)"
log "Architecture: $(uname -m)"
log "Persistent HOME: ${HOME}"

mkdir -p "${ANDROID_AVD_HOME}" /data/tmp

# Clear stale X11 files/processes left by an unclean restart.
pkill -9 Xvfb 2>/dev/null || true
pkill -9 scrcpy 2>/dev/null || true
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0

log "Starting virtual display..."
Xvfb "${DISPLAY_NUM}" -screen 0 720x1280x24 -ac &
XVFB_PID=$!

for _ in $(seq 1 20); do
    [[ -S /tmp/.X11-unix/X0 ]] && break
    kill -0 "${XVFB_PID}" 2>/dev/null || fatal "Xvfb exited unexpectedly."
    sleep 0.5
done
[[ -S /tmp/.X11-unix/X0 ]] || fatal "Xvfb did not create its display socket."

# scrcpy will be the only visible application on the X display.
fluxbox >/tmp/fluxbox.log 2>&1 &

x11vnc \
    -display "${DISPLAY_NUM}" \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 \
    >/tmp/x11vnc.log 2>&1 &
VNC_PID=$!

websockify --web=/usr/share/novnc 6080 localhost:5900 &
NOVNC_PID=$!

log "VNC is listening on port 5900 and noVNC/Ingress on port 6080."

if [[ ! -d "${ANDROID_AVD_HOME}/${AVD_NAME}.avd" ]]; then
    log "Creating persistent Android 14 virtual device '${AVD_NAME}'..."
    echo "no" | avdmanager create avd \
        --force \
        --name "${AVD_NAME}" \
        --package "${AVD_PACKAGE}" \
        --device "pixel_6"
fi

CONFIG_INI="${ANDROID_AVD_HOME}/${AVD_NAME}.avd/config.ini"
[[ -f "${CONFIG_INI}" ]] || fatal "AVD configuration was not created."

set_ini() {
    local key="$1"
    local value="$2"
    if grep -q "^${key} =" "${CONFIG_INI}"; then
        sed -i "s|^${key} =.*|${key} = ${value}|" "${CONFIG_INI}"
    else
        echo "${key} = ${value}" >> "${CONFIG_INI}"
    fi
}

set_ini "hw.lcd.width" "720"
set_ini "hw.lcd.height" "1280"
set_ini "hw.lcd.density" "320"
set_ini "hw.ramSize" "2048"
set_ini "disk.dataPartition.size" "8G"
set_ini "showDeviceFrame" "no"

find "${ANDROID_AVD_HOME}/${AVD_NAME}.avd" -name "*.lock" -exec rm -rf {} + 2>/dev/null || true

ACCEL_FLAGS=(-accel off)
BOOT_TIMEOUT=900
if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    log "KVM is accessible; enabling hardware virtualization."
    ACCEL_FLAGS=(-accel on)
    BOOT_TIMEOUT=420
else
    log "KVM is unavailable or inaccessible; using software emulation."
    log "Software-emulation boot timeout is ${BOOT_TIMEOUT} seconds."
fi

log "Starting Android emulator headlessly..."
emulator \
    -avd "${AVD_NAME}" \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot \
    -no-metrics \
    -gpu swiftshader_indirect \
    -camera-back none \
    -camera-front none \
    "${ACCEL_FLAGS[@]}" &
EMU_PID=$!

log "Emulator PID: ${EMU_PID}"
log "Waiting for ADB device..."

BOOT_DEADLINE=$((SECONDS + BOOT_TIMEOUT))
while (( SECONDS < BOOT_DEADLINE )); do
    if ! kill -0 "${EMU_PID}" 2>/dev/null; then
        wait "${EMU_PID}" || true
        fatal "Android emulator exited before ADB became available."
    fi
    if adb get-state 2>/dev/null | grep -q "^device$"; then
        break
    fi
    sleep 2
done

adb get-state >/dev/null 2>&1 || fatal "ADB did not become available within ${BOOT_TIMEOUT} seconds."

log "ADB connected. Waiting for Android boot completion..."
BOOT_DEADLINE=$((SECONDS + BOOT_TIMEOUT))
while (( SECONDS < BOOT_DEADLINE )); do
    if ! kill -0 "${EMU_PID}" 2>/dev/null; then
        wait "${EMU_PID}" || true
        fatal "Android emulator exited during boot."
    fi
    if [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
        break
    fi
    sleep 2
done

if [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; then
    log "Android properties at timeout:"
    adb shell getprop 2>/dev/null | tail -n 50 || true
    fatal "Android did not complete boot within ${BOOT_TIMEOUT} seconds."
fi

log "Android boot completed."

APK_SOURCE="/config/WhatsApp.apk"
HASH_FILE="/data/whatsapp_apk.sha256"

if [[ -f "${APK_SOURCE}" ]]; then
    NEW_HASH="$(sha256sum "${APK_SOURCE}" | awk '{print $1}')"
    OLD_HASH=""
    [[ -f "${HASH_FILE}" ]] && OLD_HASH="$(cat "${HASH_FILE}")"

    if [[ "${NEW_HASH}" != "${OLD_HASH}" ]] || ! adb shell pm path com.whatsapp >/dev/null 2>&1; then
        log "Installing/updating WhatsApp from /config/WhatsApp.apk..."
        if adb install -r -g "${APK_SOURCE}"; then
            echo "${NEW_HASH}" > "${HASH_FILE}"
            log "WhatsApp installation completed."
        else
            log "ERROR: WhatsApp APK installation failed. Android will remain available for debugging."
        fi
    else
        log "WhatsApp is already installed and the APK is unchanged."
    fi
else
    log "No /config/WhatsApp.apk found. Android will run without WhatsApp until an APK is supplied."
fi

if adb shell pm path com.whatsapp >/dev/null 2>&1; then
    log "Launching WhatsApp..."
    adb shell monkey -p com.whatsapp -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
fi

# Wake and unlock the emulator before starting the mirror.
adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
adb shell wm dismiss-keyguard >/dev/null 2>&1 || true

log "Starting scrcpy Android display..."
/opt/scrcpy/scrcpy \
    --no-audio \
    --fullscreen \
    --window-borderless \
    --window-title="AndroidWhatsApp" \
    --max-size=1280 \
    --video-bit-rate=4M \
    --max-fps=30 \
    >/tmp/scrcpy.log 2>&1 &
SCRCPY_PID=$!

sleep 2
if ! kill -0 "${SCRCPY_PID}" 2>/dev/null; then
    log "scrcpy startup log:"
    cat /tmp/scrcpy.log 2>/dev/null || true
    fatal "scrcpy failed to start."
fi

echo "============================================================"
log "Android is running and mirrored through scrcpy."
log "Open the Home Assistant Web UI/noVNC to control Android."
log "Persistent Android state is stored under /data/.android."
echo "============================================================"

# Keep the add-on alive while the emulator runs. scrcpy is restarted if it
# exits, so temporary display/mirroring failures do not kill Android.
while kill -0 "${EMU_PID}" 2>/dev/null; do
    if ! kill -0 "${SCRCPY_PID}" 2>/dev/null; then
        log "scrcpy exited; restarting it..."
        /opt/scrcpy/scrcpy \
            --no-audio \
            --fullscreen \
            --window-borderless \
            --window-title="AndroidWhatsApp" \
            --max-size=1280 \
            --video-bit-rate=4M \
            --max-fps=30 \
            >>/tmp/scrcpy.log 2>&1 &
        SCRCPY_PID=$!
    fi
    sleep 5
done

wait "${EMU_PID}" || true
fatal "Android emulator exited."
