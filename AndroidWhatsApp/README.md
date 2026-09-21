# AndroidWhatsApp

AndroidWhatsApp is a Home Assistant app/add-on that runs a persistent Android 14 virtual phone for the WhatsApp Android client.

Version 0.2.x uses the official Google Android Emulator instead of ReDroid. Android runs with its own guest kernel, so Home Assistant OS does **not** need Android Binder/BinderFS kernel support.

## Architecture

```
Home Assistant OS
  -> Home Assistant Ingress
      -> noVNC / websockify :6080
          -> x11vnc :5900
              -> Xvfb
                  -> Google Android Emulator
                      -> Android 14 Google APIs x86_64
                          -> WhatsApp
```

The app automatically uses `/dev/kvm` when Home Assistant OS exposes it. If KVM is not available it falls back to software CPU emulation, which is considerably slower.

## Home Assistant Ingress

Ingress is enabled by default. Open **AndroidWhatsApp -> Open Web UI** (or its Home Assistant sidebar panel) to control Android without exposing a separate web service publicly.

Home Assistant gives each Ingress session a dynamic URL prefix. Version 0.2.2 includes a small wrapper page that derives that prefix from the browser URL and passes the correct prefixed `websockify` WebSocket path to noVNC. This allows both the HTML and VNC WebSocket connection to remain inside Home Assistant Ingress.

Direct noVNC access is still available for troubleshooting on:

```
http://HOME_ASSISTANT_IP:6080/
```

Raw VNC is available on:

```
HOME_ASSISTANT_IP:5900
```

## Persistent state

The emulator home and AVD are stored under Home Assistant's persistent app data directory:

```
/data/.android
```

The Android installation, WhatsApp registration and WhatsApp application data therefore survive normal app restarts and upgrades.

## WhatsApp APK

The app intentionally does not distribute WhatsApp.

Place a legitimate single-file Android APK at:

```
/addon_configs/98905704_android_whatsapp/WhatsApp.apk
```

Inside the app this appears as:

```
/config/WhatsApp.apk
```

At boot AndroidWhatsApp hashes the APK and installs/updates it only when necessary.

## KVM

Watch the app log during startup. A fast configuration reports:

```
[AndroidWhatsApp] KVM is accessible; enabling hardware virtualization.
```

Without KVM:

```
[AndroidWhatsApp] KVM is unavailable or inaccessible; using software emulation.
```

Software emulation can take several minutes to boot.

## Resources

The default virtual phone uses:

- Android 14 / API 34
- Google APIs x86_64 image
- 720 x 1280 display
- 320 dpi
- 2 GB Android RAM
- up to 8 GB Android userdata

The Docker image is several GB because the Android Emulator and Android system image dominate the size; Debian slim mainly reduces the surrounding Linux userspace.

## Security

Home Assistant Ingress is the preferred browser access method because Home Assistant handles authentication before proxying requests to the app.

Direct ports 6080, 5900 and 5555 should only be exposed to a trusted LAN/VPN. Raw VNC currently uses no password, and ADB provides powerful control of Android.

## Troubleshooting

Use:

```bash
ha apps logs 98905704_android_whatsapp --follow
```

The startup script logs KVM detection, AVD creation, ADB availability, Android boot completion, APK installation and emulator failures.
