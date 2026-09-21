FROM debian:bookworm-slim

ARG BUILD_VERSION
ARG BUILD_ARCH

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:$PATH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}"

# Keep the Linux userspace small. The Android system image is by far the
# largest part of the final image.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    ca-certificates \
    curl \
    unzip \
    procps \
    libgl1 \
    libpulse0 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxrandr2 \
    libxdamage1 \
    libxfixes3 \
    fonts-dejavu-core \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

# Android command-line tools.
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
       https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -f /tmp/cmdline-tools.zip

# Android 14 Google APIs x86_64 image. This runs its own Android kernel, so it
# does not require Binder support from the Home Assistant OS host kernel.
RUN yes | sdkmanager --licenses >/dev/null \
    && sdkmanager --install \
       "platform-tools" \
       "emulator" \
       "system-images;android-34;google_apis;x86_64" \
    && rm -rf /root/.android/cache /tmp/*

RUN mkdir -p /opt/android-whatsapp \
    && printf '%s\n' \
       '<!doctype html>' \
       '<html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale"></head>' \
       '<body><a href="vnc.html?autoconnect=true&resize=scale">Open AndroidWhatsApp</a></body></html>' \
       > /usr/share/novnc/index.html

COPY entrypoint.sh /opt/android-whatsapp/entrypoint.sh
RUN chmod 0755 /opt/android-whatsapp/entrypoint.sh

EXPOSE 6080 5900 5555

ENTRYPOINT ["/opt/android-whatsapp/entrypoint.sh"]
