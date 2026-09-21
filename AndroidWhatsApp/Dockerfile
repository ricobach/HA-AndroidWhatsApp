FROM redroid/redroid:14.0.0-latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}"

# ReDroid is an Android root filesystem, not a normal Linux distro.
# Do not use RUN here: many ReDroid images do not provide /bin/sh for Docker builds.
COPY rootfs/vendor/etc/init/whatsapp.rc /vendor/etc/init/whatsapp.rc
COPY rootfs/system/bin/install-whatsapp.sh /system/bin/install-whatsapp.sh
COPY rootfs/system/bin/redroid-debug-start.sh /system/bin/redroid-debug-start.sh

# Print host/kernel/Binder diagnostics before replacing PID 1 with Android init.
ENTRYPOINT ["/system/bin/sh", "/system/bin/redroid-debug-start.sh"]
