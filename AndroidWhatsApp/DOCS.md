# AndroidWhatsApp 0.2.0

This version runs the official Google Android Emulator instead of ReDroid.

## First start

The first build is large because it downloads the Android Emulator and Android 14 x86_64 system image. The first Android boot can also take several minutes, particularly if `/dev/kvm` is not available.

After startup, open **Web UI** to see the Android screen through noVNC.

## Install WhatsApp

Put a legitimate single-file `WhatsApp.apk` in the AndroidWhatsApp app configuration directory:

```
/addon_configs/98905704_android_whatsapp/WhatsApp.apk
```

Restart AndroidWhatsApp. The startup script installs it after Android finishes booting.

## Logs

```bash
ha apps logs 98905704_android_whatsapp --follow
```

Look for the KVM line first. Hardware acceleration is strongly preferred but software emulation is supported as a fallback.
