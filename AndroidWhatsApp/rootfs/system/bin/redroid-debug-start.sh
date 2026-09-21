#!/system/bin/sh

echo "============================================================"
echo "[AndroidWhatsApp DEBUG] Early container startup diagnostics"
echo "============================================================"
echo "[DEBUG] Date:"
date 2>&1 || true

echo "[DEBUG] Identity:"
id 2>&1 || true

echo "[DEBUG] Kernel / architecture:"
uname -a 2>&1 || true

echo "[DEBUG] /proc/cmdline:"
cat /proc/cmdline 2>&1 || true

echo "[DEBUG] Binder-related filesystems:"
grep -i binder /proc/filesystems 2>&1 || echo "[DEBUG] No binder entry in /proc/filesystems"

echo "[DEBUG] Binder kernel module:"
if [ -d /sys/module/binder_linux ]; then
    echo "[DEBUG] /sys/module/binder_linux exists"
    if [ -f /sys/module/binder_linux/parameters/devices ]; then
        echo -n "[DEBUG] binder_linux devices parameter: "
        cat /sys/module/binder_linux/parameters/devices 2>&1 || true
    fi
else
    echo "[DEBUG] /sys/module/binder_linux NOT present"
fi

echo "[DEBUG] Expected Android Binder devices:"
for dev in /dev/binder /dev/hwbinder /dev/vndbinder; do
    if [ -e "$dev" ]; then
        ls -l "$dev" 2>&1 || true
    else
        echo "[DEBUG] MISSING: $dev"
    fi
done

echo "[DEBUG] BinderFS:"
if [ -e /dev/binderfs ]; then
    ls -la /dev/binderfs 2>&1 || true
else
    echo "[DEBUG] /dev/binderfs is not present"
fi

echo "[DEBUG] Binder-related mounts:"
mount 2>&1 | grep -i binder || echo "[DEBUG] No binder-related mounts found"

echo "[DEBUG] Relevant directories:"
for dir in /data /config /dev; do
    if [ -e "$dir" ]; then
        echo "[DEBUG] $dir exists:"
        ls -ld "$dir" 2>&1 || true
    else
        echo "[DEBUG] MISSING directory: $dir"
    fi
done

echo "[DEBUG] WhatsApp APK:"
if [ -f /config/WhatsApp.apk ]; then
    ls -l /config/WhatsApp.apk 2>&1 || true
else
    echo "[DEBUG] /config/WhatsApp.apk not present (this is OK for boot testing)"
fi

echo "[DEBUG] Android init executable:"
ls -l /init 2>&1 || true

echo "[DEBUG] Starting ReDroid /init now..."
echo "============================================================"

exec /init \
    qemu=1 \
    androidboot.hardware=redroid \
    ro.setupwizard.mode=DISABLED \
    androidboot.redroid_gpu_mode=guest \
    androidboot.redroid_width=720 \
    androidboot.redroid_height=1280 \
    androidboot.redroid_dpi=320
