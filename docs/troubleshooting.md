# Antigravity Mobile — Troubleshooting Guide

| Symptom / Error Code | Root Cause | Resolution |
| :--- | :--- | :--- |
| `E_TERMUX_MISSING` | Termux is missing or blocked by Android 11+ `<queries>` | Install official ARM64 Termux (`com.termux`), launch it once, then tap **Re-check**. |
| `E_RUN_COMMAND_DENIED` | Runtime permission `com.termux.permission.RUN_COMMAND` not granted | Tap **Grant Permission** on Setup tab or open **App Settings -> Additional permissions**. |
| `E_EXTERNAL_APPS_DISABLED` | `allow-external-apps=true` is missing or commented in `~/.termux/termux.properties` | Run the setup snippet in Termux and execute `termux-reload-settings`. |
| `E_WRAPPER_MISSING` | `~/.antigravity-mobile/bin/agy-wrapper.sh` is missing or not executable | Run the exported `TermuxSetupInstaller` script in Termux or copy `runtime/scripts/*` + `runtime/doctor/agy-doctor.sh` into `~/.antigravity-mobile/bin/` (`chmod 700`). |
| `E_WRAPPER_OUTDATED` | Installed Termux wrapper version differs from APK expected `v1.1.0` | Export and run the updated `TermuxSetupInstaller` script from **Setup** to refresh scripts atomically with SHA-256 verification. |
| `E_LOW_STORAGE` | Free Termux `$HOME` storage is below `1024 MiB` | Free device storage before bootstrapping Debian ARM64 PRoot, then re-run **Doctor**. |
| `E_TIMEOUT` | Termux battery optimization killed background `RunCommandService` or wrapper stalled | Exempt Termux from Android Battery Optimization (`Unrestricted`) and re-run **Doctor**. |
| `E_CLI_ARCH_MISMATCH` | Non-ARM64 CLI binary detected | Remove invalid binary and install the official Linux `aarch64` / `arm64` Antigravity CLI. |
| `E_AUTH_REQUIRED` | Antigravity CLI session is unauthenticated | Tap **Open Termux**, enter `proot-distro login debian`, and complete the official CLI login flow. |
| `E_NETWORK_TLS` | DNS or CA certificates failing inside PRoot | Verify `/etc/resolv.conf` and install `ca-certificates` inside Debian PRoot. |
