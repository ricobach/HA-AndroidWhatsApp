# AndroidWhatsApp

AndroidWhatsApp is a Home Assistant app/add-on that runs a persistent Android 14 virtual phone for the WhatsApp Android client.

Version 0.2.3 uses a **headless Google Android Emulator** and mirrors only the Android display through **scrcpy**. This avoids showing the Android Emulator's desktop window, frame and side toolbar in noVNC.

## Architecture

```
Home Assistant OS
  -> Google Android Emulator (headless)
      -> Android 14
          -> ADB
              -> scrcpy
                  -> Xvfb
                      -> x11vnc :5900
                          -> noVNC / Home Assistant Ingress :6080
```

The emulator has its own guest kernel, so Home Assistant OS does not need Android Binder/BinderFS support.

## Display

The emulator itself runs with `-no-window`. Once Android completes boot, scrcpy creates a fullscreen, borderless 720x1280 mirror on Xvfb. noVNC and raw VNC therefore show the Android screen rather than the Android Emulator Qt UI.

scrcpy 4.1 is downloaded from the official Genymobile release and its SHA-256 is verified during the image build.

## Home Assistant Ingress

Ingress is enabled by default. Open **AndroidWhatsApp -> Open Web UI** or the sidebar entry.

Direct troubleshooting access remains available:

```
noVNC: http://HOME_ASSISTANT_IP:6080/
VNC:   HOME_ASSISTANT_IP:5900
ADB:   HOME_ASSISTANT_IP:5555
```

## KVM and boot time

When `/dev/kvm` is accessible, AndroidWhatsApp uses hardware virtualization and a 7-minute boot timeout.

Without KVM it uses QEMU software emulation (TCG) and allows up to 15 minutes for both ADB availability and Android boot completion.

## Persistent state

The emulator AVD and user data are stored under:

```
/data/.android
```

so Android and WhatsApp state survive app restarts and upgrades.

## WhatsApp APK

Place a legitimate single-file APK at:

```
/addon_configs/98905704_android_whatsapp/WhatsApp.apk
```

It appears inside the app as `/config/WhatsApp.apk` and is installed/updated automatically after Android boots.

## Logs

```bash
ha apps logs 98905704_android_whatsapp --follow
```

Useful messages include KVM detection, ADB connection, Android boot completion, WhatsApp installation and scrcpy startup.
