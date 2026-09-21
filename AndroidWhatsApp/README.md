# AndroidWhatsApp

AndroidWhatsApp is a Home Assistant app/add-on that runs a persistent Android 14 virtual phone for the WhatsApp Android client.

Version 0.2.0 replaces the previous ReDroid approach with the official Google Android Emulator. Android now runs with its own guest kernel, so the Home Assistant OS host does **not** need Android Binder/BinderFS kernel support.

## Architecture

```
Home Assistant OS
  -> AndroidWhatsApp container (Debian slim)
      -> Google Android Emulator
          -> Android 14 Google APIs x86_64
              -> WhatsApp
      -> Xvfb + x11vnc + noVNC
```

The app uses `/dev/kvm` automatically when Home Assistant OS exposes it. If KVM is not available it falls back to software CPU emulation, which will be considerably slower.

## Persistent state

The emulator home and AVD are stored under Home Assistant's persistent app data directory:

```
/data/.android
```

That means the Android installation, WhatsApp registration and WhatsApp application data survive normal app restarts and upgrades.

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

## Browser access

noVNC runs on port 6080 and is configured as the Home Assistant app Web UI/Ingress endpoint. Open **AndroidWhatsApp -> Open Web UI** to control the virtual phone.

Direct fallback URL:

```
http://HOME_ASSISTANT_IP:6080/vnc.html?autoconnect=true&resize=scale
```

## KVM

Watch the app log during startup. A fast configuration reports:

```
[AndroidWhatsApp] KVM is accessible; enabling hardware virtualization.
```

Without KVM it reports:

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

The Docker image itself is several GB because the Android Emulator and Android system image dominate the size; using Debian slim mainly reduces the surrounding Linux userspace.

## Security

Port 6080 currently has no VNC password and should only be exposed to a trusted LAN/VPN. ADB access is also powerful and must not be forwarded to the public Internet.

## Troubleshooting

Use:

```bash
ha apps logs 98905704_android_whatsapp --follow
```

The startup script logs KVM detection, AVD creation, ADB availability, Android boot completion, APK installation and emulator failures.
