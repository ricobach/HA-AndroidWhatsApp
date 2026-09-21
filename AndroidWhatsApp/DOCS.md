# AndroidWhatsApp 0.2.2

AndroidWhatsApp runs an Android 14 Google Emulator with persistent storage and browser control.

## Home Assistant Ingress

Use **Open Web UI** or the **AndroidWhatsApp** Home Assistant sidebar entry.

The noVNC frontend is served through Home Assistant Ingress on the app's internal port 6080. AndroidWhatsApp automatically derives the current Ingress session prefix and uses it for the noVNC `websockify` WebSocket connection.

This means you do not need to know or bookmark the generated `/api/hassio_ingress/.../` URL.

For troubleshooting only, direct noVNC remains available on port 6080 and raw VNC on port 5900.

## Install WhatsApp

Put a legitimate single-file `WhatsApp.apk` in:

```
/addon_configs/98905704_android_whatsapp/WhatsApp.apk
```

Restart AndroidWhatsApp. The startup script installs it after Android completes boot.

## Logs

```bash
ha apps logs 98905704_android_whatsapp --follow
```

Hardware acceleration is strongly preferred. If KVM is unavailable, AndroidWhatsApp automatically uses software emulation.
