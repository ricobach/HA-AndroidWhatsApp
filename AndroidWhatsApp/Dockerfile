FROM alpine:3.20 AS debug-tools
RUN apk add --no-cache busybox-static

FROM redroid/redroid:14.0.0-latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}"

# ReDroid's Android userspace does not provide a normal Linux shell/loader
# before /init starts. Alpine's busybox-static package installs the truly
# static binary as /bin/busybox.static; using /bin/busybox here would depend
# on Alpine's musl loader and fail in the Android rootfs with ENOENT.
COPY --from=debug-tools /bin/busybox.static /debug/busybox
COPY rootfs/system/bin/redroid-debug-start.sh /debug/start.sh

# Files consumed after Android has mounted its normal root filesystem.
COPY rootfs/vendor/etc/init/whatsapp.rc /vendor/etc/init/whatsapp.rc
COPY rootfs/system/bin/install-whatsapp.sh /system/bin/install-whatsapp.sh

# Run diagnostics with a static shell, then exec ReDroid's native /init.
ENTRYPOINT ["/debug/busybox", "sh", "/debug/start.sh"]
