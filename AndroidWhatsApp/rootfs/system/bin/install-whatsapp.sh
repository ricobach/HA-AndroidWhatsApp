#!/system/bin/sh

APK_SOURCE="/config/WhatsApp.apk"
APK_TMP="/data/local/tmp/WhatsApp.apk"
HASH_FILE="/data/local/whatsapp_apk.sha256"
PACKAGE="com.whatsapp"

log -t HA-WhatsApp "WhatsApp installer started"

# Supervisor mounts addon_config at /config.
# Allow a little time for all mounts/services to settle.
i=0
while [ ! -f "$APK_SOURCE" ] && [ "$i" -lt 60 ]; do
    sleep 2
    i=$((i + 1))
done

if [ ! -f "$APK_SOURCE" ]; then
    log -t HA-WhatsApp "No /config/WhatsApp.apk found; leaving Android running without WhatsApp"
    exit 0
fi

# Android toybox provides sha256sum on current AOSP builds.
NEW_HASH="$(sha256sum "$APK_SOURCE" 2>/dev/null | cut -d' ' -f1)"
OLD_HASH=""
[ -f "$HASH_FILE" ] && OLD_HASH="$(cat "$HASH_FILE" 2>/dev/null)"

if [ -n "$NEW_HASH" ] && [ "$NEW_HASH" = "$OLD_HASH" ] && pm path "$PACKAGE" >/dev/null 2>&1; then
    log -t HA-WhatsApp "WhatsApp APK unchanged and already installed"
    exit 0
fi

cp "$APK_SOURCE" "$APK_TMP" || exit 1
chmod 0644 "$APK_TMP"

log -t HA-WhatsApp "Installing/updating WhatsApp"
if pm install -r -g "$APK_TMP"; then
    [ -n "$NEW_HASH" ] && echo "$NEW_HASH" > "$HASH_FILE"
    rm -f "$APK_TMP"
    log -t HA-WhatsApp "WhatsApp installation completed"
    exit 0
fi

log -t HA-WhatsApp "WhatsApp installation failed"
exit 1
