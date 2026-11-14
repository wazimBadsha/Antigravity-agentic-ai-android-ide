# Antigravity Mobile — Pixel 7a (ARM64) Setup Guide

## Architecture Overview
Antigravity Mobile is a native Android launcher and runtime orchestrator:
`Android APK -> Termux (RUN_COMMAND) -> Reviewed Wrapper -> PRoot-Distro -> Debian ARM64 -> Official Antigravity CLI`

It does **not** bundle a Debian root filesystem, convert a Linux `.deb` into an APK, or fork Antigravity.

## Prerequisites on Google Pixel 7a
1. **Install Termux** (`com.termux`) from an official ARM64 release (GitHub Releases or F-Droid — avoid outdated Play Store builds).
2. Open Termux once so `~/.termux` and `/data/data/com.termux/files/usr` initialize.
3. Enable external command execution inside Termux:
   ```bash
   mkdir -p ~/.termux ~/.antigravity-mobile/bin
   grep -q '^allow-external-apps=true' ~/.termux/termux.properties 2>/dev/null || echo 'allow-external-apps=true' >> ~/.termux/termux.properties
   termux-reload-settings
   ```
4. Install the reviewed `v1.1.0` scripts into Termux (recommended: tap **Export Setup Script** / **Copy Installer** on the app's **Setup** screen using `TermuxSetupInstaller`, or copy manually from `runtime/`):
   - `runtime/scripts/agy-wrapper.sh` -> `~/.antigravity-mobile/bin/agy-wrapper.sh` (`chmod 700`)
   - `runtime/scripts/agy-bootstrap.sh` -> `~/.antigravity-mobile/bin/agy-bootstrap.sh` (`chmod 700`)
   - `runtime/doctor/agy-doctor.sh` -> `~/.antigravity-mobile/bin/agy-doctor.sh` (`chmod 700`)
   - `runtime/extensions/mcp/readonly-fs-mcp.json` -> `~/.antigravity-mobile/extensions/mcp/readonly-fs-mcp.json` (`chmod 600`)
5. Install **Antigravity Mobile** (`Antigravity-Mobile-debug.apk` from GitHub Releases or `app/build/outputs/apk/debug/app-debug.apk`).
6. On the **Setup** tab, grant Android permission `com.termux.permission.RUN_COMMAND` (or enable it under Android App Info -> Permissions -> Additional permissions).
7. Tap **Bootstrap** or **Run Doctor** to install/verify `proot-distro`, `debian` (ARM64), glibc/libstdc++, DNS/HTTPS, available storage (`>= 1024 MiB`), and the official Antigravity CLI.
8. For CLI login, tap **Open Termux** and complete the official interactive authentication inside Debian PRoot.
