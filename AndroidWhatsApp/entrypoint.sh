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
    if [[ -n "${EMU_PID:-}" ]] && kill -0 "${EMU_PID}" 2>/dev/null; then
        kill "${EMU_PID}" 2>/dev/null || true
    fi
    if [[ -n "${NOVNC_PID:-}" ]] && kill -0 "${NOVNC_PID}" 2>/dev/null; then
        kill "${NOVNC_PID}" 2>/dev/null || true
    fi
    if [[ -n "${VNC_PID:-}" ]] && kill -0 "${VNC_PID}" 2>/dev/null; then
        kill "${VNC_PID}" 2>/dev/null || true
    fi
    if [[ -n "${XVFB_PID:-}" ]] && kill -0 "${XVFB_PID}" 2>/dev/null; then
        kill "${XVFB_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT TERM INT

echo "============================================================"
echo " AndroidWhatsApp 0.2.2 - Android Emulator"
echo "============================================================"
log "Kernel: $(uname -a)"
log "Architecture: $(uname -m)"
log "Persistent HOME: ${HOME}"

if [[ -e /dev/kvm ]]; then
    log "/dev/kvm exists: $(ls -l /dev/kvm)"
else
    log "/dev/kvm is not present; software CPU emulation will be used."
fi

mkdir -p "${ANDROID_AVD_HOME}" /data/tmp

# Clear stale X11 files from an unclean previous shutdown.
pkill -9 Xvfb 2>/dev/null || true
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

log "Starting lightweight window manager and noVNC..."
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
if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    log "KVM is accessible; enabling hardware virtualization."
    ACCEL_FLAGS=(-accel on)
else
    log "KVM is unavailable or inaccessible; using software emulation."
fi

log "Starting Android emulator..."
set +e
emulator \
    -avd "${AVD_NAME}" \
    -no-audio \
    -no-boot-anim \
    -no-snapshot \
    -no-metrics \
    -gpu swiftshader_indirect \
    -camera-back none \
    -camera-front none \
    "${ACCEL_FLAGS[@]}" &
EMU_PID=$!
set -e

log "Emulator PID: ${EMU_PID}"
log "Waiting for ADB device..."

BOOT_DEADLINE=$((SECONDS + 420))
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

adb get-state >/dev/null 2>&1 || fatal "ADB did not become available within 7 minutes."

log "ADB connected. Waiting for Android boot completion..."
BOOT_DEADLINE=$((SECONDS + 420))
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
    fatal "Android did not complete boot within 7 minutes."
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

echo "============================================================"
log "Android is running."
log "Open the app Web UI/noVNC to control the virtual phone."
log "Persistent Android state is stored under /data/.android."
echo "============================================================"

# Keep PID 1 attached to the emulator process. If it exits, Supervisor can
# report/restart the app instead of leaving a dead Android instance behind.
wait "${EMU_PID}"
