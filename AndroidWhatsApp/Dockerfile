FROM debian:bookworm-slim

ARG BUILD_VERSION
ARG BUILD_ARCH

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    SCRCPY_VERSION=4.1 \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:/opt/scrcpy:$PATH

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}"

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

# Android 14 Google APIs x86_64 image.
RUN yes | sdkmanager --licenses >/dev/null \
    && sdkmanager --install \
       "platform-tools" \
       "emulator" \
       "system-images;android-34;google_apis;x86_64" \
    && rm -rf /root/.android/cache /tmp/*

# Official scrcpy Linux x86_64 release. It provides the desktop client and
# bundled server used to mirror/control the headless emulator through ADB.
RUN curl -fsSL -o /tmp/scrcpy.tar.gz \
       "https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VERSION}/scrcpy-linux-x86_64-v${SCRCPY_VERSION}.tar.gz" \
    && echo "ad56ae8bfeedf41e824945c11dbf55fcb092b3e615b9b486f48a50e30d389635  /tmp/scrcpy.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/scrcpy \
    && tar -xzf /tmp/scrcpy.tar.gz --strip-components=1 -C /opt/scrcpy \
    && rm -f /tmp/scrcpy.tar.gz

RUN mkdir -p /opt/android-whatsapp
COPY ingress-index.html /usr/share/novnc/index.html
COPY entrypoint.sh /opt/android-whatsapp/entrypoint.sh
RUN chmod 0755 /opt/android-whatsapp/entrypoint.sh

EXPOSE 6080 5900 5555

ENTRYPOINT ["/opt/android-whatsapp/entrypoint.sh"]
