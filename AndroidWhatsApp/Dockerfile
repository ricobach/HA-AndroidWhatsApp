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

ENTRYPOINT ["/init", "qemu=1", "androidboot.hardware=redroid", "ro.setupwizard.mode=DISABLED", "androidboot.redroid_gpu_mode=guest", "androidboot.redroid_width=720", "androidboot.redroid_height=1280", "androidboot.redroid_dpi=320"]
