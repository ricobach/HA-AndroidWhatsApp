# ReDroid WhatsApp for Home Assistant

Prototype Home Assistant app/add-on that runs ReDroid Android 14 and automatically installs the official WhatsApp Android APK supplied by the user.

## What this version does

- Uses `redroid/redroid:14.0.0-latest` directly as its Docker base image.
- Keeps ReDroid's native Android `/init` entrypoint.
- Uses Home Assistant's persistent `/data` mount as Android's persistent data partition.
- Mounts the add-on-specific config folder at `/config`.
- Installs or updates `/config/WhatsApp.apk` after Android reports `sys.boot_completed=1`.
- Exposes ADB on TCP port 5555.
- Uses software rendering (`androidboot.redroid_gpu_mode=guest`) for maximum compatibility.

## Important Home Assistant OS limitation

ReDroid needs Linux Binder support and normally runs with Docker `--privileged`. This app therefore requests `full_access: true` and disables AppArmor. It will only work if the Home Assistant OS/kernel on the target machine exposes the Binder functionality ReDroid needs. This is the main item that must be tested on the target Home Assistant host.

If Android exits immediately, inspect the app log and host kernel log for Binder errors.

## Installation as a local app

1. Copy the `redroid_whatsapp` directory into the local Home Assistant apps/add-ons directory.
2. Reload the app store and install **ReDroid WhatsApp**.
3. Disable protection mode for this app if Supervisor requires it for `full_access`.
4. Start it once so Home Assistant creates the app-specific config directory.
5. Put a legitimate copy of the WhatsApp Android APK in the add-on config directory and name it exactly:

   `WhatsApp.apk`

   Inside the ReDroid container it is mounted as `/config/WhatsApp.apk`.
6. Restart the app.

## Connecting to Android

From another computer with Android platform tools installed:

```bash
adb connect HOME_ASSISTANT_IP:5555
adb devices
```

Then use scrcpy:

```bash
scrcpy -s HOME_ASSISTANT_IP:5555
```

The Android state, WhatsApp login and app data live under the persistent `/data` volume and should survive app restarts/upgrades unless that data is deleted.

## WhatsApp APK format

This prototype expects a single installable APK. Some distribution sources provide split APK/App Bundle packages instead of one APK; those require a different installer flow (`install-multiple`) and are not handled by v0.1.0.

## Security

ADB port 5555 provides powerful control of the Android instance. Do not expose it directly to the Internet. Restrict it to a trusted LAN/VPN/firewall segment.

## Next step

The intended v0.2 architecture is to add a browser-based scrcpy frontend so the Android screen can be opened from Home Assistant rather than requiring desktop scrcpy.
