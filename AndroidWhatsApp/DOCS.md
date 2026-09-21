# AndroidWhatsApp 0.2.3

This release changes the browser/VNC display from the Android Emulator desktop window to a clean **scrcpy mirror of the Android screen**.

The emulator itself runs headlessly. After Android boots, scrcpy opens fullscreen on the virtual X display and noVNC exposes that display through Home Assistant Ingress.

## First start

If KVM is unavailable, software emulation is used and the first boot can be slow. Version 0.2.3 allows up to 15 minutes in software-emulation mode.

Use:

```bash
ha apps logs 98905704_android_whatsapp --follow
```

Wait for:

```
[AndroidWhatsApp] Android boot completed.
[AndroidWhatsApp] Starting scrcpy Android display...
[AndroidWhatsApp] Android is running and mirrored through scrcpy.
```

## Access

Preferred:

**AndroidWhatsApp -> Open Web UI**

Troubleshooting:

```
noVNC: http://HOME_ASSISTANT_IP:6080/
VNC:   HOME_ASSISTANT_IP:5900
```

## Install WhatsApp

Put a legitimate single-file `WhatsApp.apk` in:

```
/addon_configs/98905704_android_whatsapp/WhatsApp.apk
```

Restart the app. It will install/update the APK after Android finishes booting.
