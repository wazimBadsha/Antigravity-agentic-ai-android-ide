# Antigravity Mobile

[![Android CI](https://github.com/wazimBadSha/Antigravity-agentic-ai-android-ide/actions/workflows/android-ci.yml/badge.svg)](https://github.com/wazimBadSha/Antigravity-agentic-ai-android-ide/actions/workflows/android-ci.yml)

Native Android launcher, runtime orchestrator, and local polyglot IDE targeting **Google Pixel 7a (ARM64)** for running the official **Antigravity CLI** inside **Termux + PRoot-Distro + Debian ARM64**.

> **Project Disclaimer:** Antigravity Mobile is an independent Android companion launcher and workspace orchestrator. It is not affiliated with, endorsed by, or an official distribution of Google LLC. It does not bundle Debian root filesystems or bypass upstream Antigravity CLI authentication.

---

## 1. Project Overview

Antigravity Mobile bridges two workflows in a single Jetpack Compose Android application (`com.aistudio.antigravitymobile.wqkvb`):

1. **Runtime Launcher & Orchestrator**: Validates Termux availability, `com.termux.permission.RUN_COMMAND` permissions, external-app enablement, reviewed wrapper scripts (`v1.1.0`), PRoot Debian ARM64 health, and official Antigravity CLI installation/authentication via a typed 8-state machine.
2. **Mobile Polyglot IDE Workspace**: Provides multi-project code editing, Room-persisted project/file storage (schema `v4`), syntax highlighting across seven languages, Copilot-style inline suggestions, Command Palette, Snippet Library, Side-by-Side Diff viewer, Git integration dialog, Terminal highlighting, and explicit SHA-256 guarded synchronization with Debian workspaces.

## 2. Why This Architecture Exists

Running desktop/Linux developer CLIs directly on unrooted Android is constrained by Android's SELinux `noexec` app-data restrictions, bionic vs. glibc dynamic linking differences, and scoped filesystem boundaries. Attempting to repackage a `.deb` binary directly into an APK or embedding fake terminal responses fails real developer workflows.

Instead, Antigravity Mobile keeps **execution inside Termux + Debian ARM64 PRoot** while keeping the **UI, project editing, command allowlisting, diagnostics, and redacted logging** in a clean native Kotlin/Compose Android client.

## 3. Target Device & Compatibility

- **Primary Target**: Google Pixel 7a (`arm64-v8a` / `aarch64`)
- **Android SDK**: `minSdk 24` (Android 7.0), `targetSdk 36`, `compileSdk 36.1`
- **CPU Architecture Policy**: Strictly targets ARM64 (`arm64-v8a` / `aarch64`) for Termux Debian PRoot runtime checks.
- **Prerequisites on Device**:
  - Official ARM64 **Termux** (`com.termux`) from GitHub Releases or F-Droid (legacy Play Store builds are unsupported).
  - Android permission `com.termux.permission.RUN_COMMAND`.
  - `allow-external-apps=true` in `~/.termux/termux.properties`.

## 4. High-Level Architecture

```text
+-------------------------------------------------------------------+
|                     Antigravity Mobile APK                        |
|  - Jetpack Compose UI (Runtime Launcher & Polyglot IDE Studio)    |
|  - Typed 8-State Machine & DoctorReportParser                     |
|  - Room v4 DB + DataStore Non-Secret Preferences                  |
|  - CommandValidator (Strict Allowlist) + LogRedactor              |
+---------------------------------+---------------------------------+
                                  |
            Intent: com.termux.RUN_COMMAND + PendingIntent
            Fixed Script: ~/.antigravity-mobile/bin/agy-wrapper.sh
                                  |
                                  v
+-------------------------------------------------------------------+
|                   Termux (com.termux, ARM64)                      |
|  - ~/.antigravity-mobile/bin/agy-wrapper.sh   (v1.1.0, chmod 700) |
|  - ~/.antigravity-mobile/bin/agy-bootstrap.sh (v1.1.0, chmod 700) |
|  - ~/.antigravity-mobile/bin/agy-doctor.sh    (v1.1.0, chmod 700) |
|  - ~/antigravity-workspaces/<slug>/                               |
+---------------------------------+---------------------------------+
                                  |
                     proot-distro login debian
                                  |
                                  v
+-------------------------------------------------------------------+
|               Debian ARM64 PRoot User-Space Guest                 |
|  - glibc / libstdc++ / ca-certificates / git / toolchains         |
|  - Official Antigravity CLI (aarch64)                             |
|  - Read-only MCP & Extension Templates (opt-in)                   |
+-------------------------------------------------------------------+
```

## 5. Key Implemented Capabilities

- **8-State Typed Runtime Machine** (`RuntimeState.kt`):
  `TERMUX_NOT_INSTALLED` → `TERMUX_NOT_AUTHORIZED` → `RUNTIME_MISSING` → `RUNTIME_BROKEN` → `RUNTIME_READY` → `AGY_STARTING` → `AGY_RUNNING` → `AGY_FAILED`.
- **Self-Verifying Termux Installer Generator** (`TermuxSetupInstaller.kt`): Generates an atomic Bash setup script encoding bundled `v1.1.0` wrapper, bootstrap, doctor, and MCP config files with SHA-256 verification and strict `chmod 700`/`600` permissions, exportable via `FileProvider`.
- **Runtime Doctor** (`agy-doctor.sh` + `DoctorReportParser.kt`): Checks device ABI, Termux storage (`>= 1024 MiB`), wrapper version parity (`1.1.0`), `proot-distro`, Debian ARM64 rootfs, glibc/libstdc++, DNS/HTTPS TLS, Antigravity CLI version/architecture, auth readiness, and MCP template status.
- **Workspace Sync & Conflict Protection** (`WorkspaceSyncManager.kt` + Room `v4`): Synchronizes local Room project files into Debian PRoot workspaces over Base64-validated IPC (`<= 49,152` raw bytes / `<= 65,536` Base64 chars per file) with optimistic SHA-256 base-hash conflict detection (wrapper exit code `40`) and non-destructive `MIGRATION_1_2`, `MIGRATION_2_3`, `MIGRATION_3_4`.
- **Real Termux Command Execution** (`TerminalCommandExecutor.kt`): Executes allowlisted Debian workspace commands (`doctor`, `check-mcp`, `mcp list`, `pwd`, `ls`, `tree`, `cat`, `grep`, `env`, `uname`, `git status|log|diff|checkout|push|pull`, `run`, `build`) in `REAL_TERMUX_RUNTIME` mode without silent fallback to simulation.
- **Polyglot IDE Workspace** (`MainActivity.kt` & `ui/components/`):
  - Multi-language editor & syntax highlighter (Kotlin, Python, Rust, TypeScript, Go, C++, Bash)
  - Project Explorer, Project Switcher, Language Config dialog, Search & Replace with Regex
  - Command Palette, Code Snippet Library, Auto-Save indicator, Copilot-style inline suggestions
  - Side-by-Side Diff Viewer & Git Integration dialog
  - Live Preview view & Terminal Output Highlighter

## 6. Security Model & Trust Boundaries

Detailed in [`docs/security.md`](docs/security.md):
- **PRoot Is Not a Sandbox**: `proot-distro` is a user-space compatibility layer, not kernel namespace/cgroup isolation. Production usage prohibits `--no-sandbox` (`SecurityPolicy.kt`).
- **Command Injection Defense**: `CommandValidator` allows only a fixed entrypoint (`~/.antigravity-mobile/bin/agy-wrapper.sh`) and a strict argument allowlist (`doctor`, `bootstrap`, `start-interactive`, `start-headless`, `stop`, `recover`, `reset`, `check-mcp`, `workspace-exec`, `workspace-sync-file`, `workspace-git`, `workspace-build`), rejecting shell metacharacters (`; | & $ \` > < ( ) quotes newlines`) and `..` path traversal.
- **Secret & Log Hygiene**: `LogRedactor` masks Bearer/Authorization tokens, cookies, API keys (`AIza...`, `sk-...`, `ghp_...`, `github_pat_...`, `ck_`/`cs_`), URL credentials, and email addresses prior to log storage or diagnostic export.
- **No Embedded Credentials**: API keys, keystores, `.env`, and signing secrets are excluded via `.gitignore`.
- **Optional Commerce Boundary**: Disabled by default and strictly decoupled from core APK readiness.

## 7. Repository Structure

```text
.
├── .github/workflows/          # GitHub Actions CI & Release workflows
├── app/
│   ├── build.gradle.kts        # Android module config (AGP 9.1.1, Compose, Room v4)
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── assets/runtime/ # Bundled Termux scripts & MCP config (v1.1.0)
│       │   ├── java/com/example/
│       │   │   ├── data/       # Room DB v4, entities, DataStore preferences, models
│       │   │   ├── domain/     # RuntimeState, DoctorModels, ProvenanceModels, Ops
│       │   │   ├── engine/     # Syntax highlighter, Diff, Copilot, IDE actions
│       │   │   ├── runtime/    # Orchestrator, Doctor parser, Terminal & Sync managers
│       │   │   ├── security/   # CommandValidator, LogRedactor, SecurityPolicy
│       │   │   ├── termux/     # RUN_COMMAND adapter, BroadcastReceiver, Installer
│       │   │   ├── ui/         # Jetpack Compose IDE & Runtime Launcher screens
│       │   │   ├── util/       # FileProvider sharing helper
│       │   │   └── viewmodel/  # AntigravityViewModel & RuntimeLauncherViewModel
│       │   └── res/            # Adaptive launcher icon, strings, XML configs
│       └── test/               # 41 JVM + Robolectric unit tests (12 test classes)
├── artifacts/                  # Release metadata, SHA-256 checksums, download notes
├── docs/                       # Setup, Security, Termux IPC, and Troubleshooting docs
├── gradle/                     # Version catalog (libs.versions.toml) & Gradle wrapper
├── runtime/                    # Canonical Termux scripts, doctor, extensions, manifests
│   ├── doctor/agy-doctor.sh
│   ├── extensions/             # Agents, hooks, MCP, plugin, rules, skills templates
│   ├── manifests/provenance-manifest.template.json
│   └── scripts/                # agy-bootstrap.sh & agy-wrapper.sh
├── build.gradle.kts
├── gradle.properties
├── gradlew / gradlew.bat
└── settings.gradle.kts
```

## 8. Prerequisites

### Local Workstation / CI Build
- JDK **21** (Temurin / Eclipse Adoptium recommended)
- Android SDK Platform **36** & Build Tools (`compileSdk 36.1`, `targetSdk 36`, `minSdk 24`)
- Gradle **9.3.1** (provided via `./gradlew` wrapper)

### Target Android Device (Pixel 7a)
- Android 13+ ARM64 (`arm64-v8a`)
- Termux (`com.termux`) with `allow-external-apps=true`
- Network access during initial PRoot Debian bootstrap & CLI setup
- Recommended free internal storage: `>= 1024 MiB` inside Termux `$HOME`

## 9. Local Build Instructions

Clone the repository and generate an ephemeral local debug keystore if one is not already present at repo root (`app/build.gradle.kts` references `${rootDir}/debug.keystore` for `debugConfig` signing):

```bash
git clone https://github.com/wazimBadSha/Antigravity-agentic-ai-android-ide.git
cd Antigravity-agentic-ai-android-ide

if [ ! -f debug.keystore ]; then
  keytool -genkeypair -v \
    -keystore debug.keystore \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

./gradlew :app:testDebugUnitTest
./gradlew :app:lintDebug
./gradlew :app:assembleDebug
```

Built Debug APK path: `app/build/outputs/apk/debug/app-debug.apk`.

## 10. Downloadable APK Releases

Pre-built Debug APKs are **not** stored inside Git commit history; they are published through GitHub:

- **GitHub Releases**: [Download latest Antigravity Mobile release](https://github.com/wazimBadSha/Antigravity-agentic-ai-android-ide/releases)
- **GitHub Actions Artifacts**: Every push/PR on `main` runs `.github/workflows/android-ci.yml` and attaches `Antigravity-Mobile-debug-apk` (including `Antigravity-Mobile-debug.apk` and `SHA256SUMS.txt`).
- **Release Manifest & Checksums**: See [`artifacts/README.md`](artifacts/README.md), [`artifacts/SHA256SUMS.txt`](artifacts/SHA256SUMS.txt), and [`artifacts/release-manifest.json`](artifacts/release-manifest.json).

> **Release APK Note:** Signed Release APK builds (`:app:assembleRelease`) require production keystore credentials configured via GitHub Actions Secrets (`ANDROID_KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`) or local environment variables. Without them, only the signed Debug APK is produced.

## 11. Installing on Google Pixel 7a

1. Download `Antigravity-Mobile-debug.apk` and `SHA256SUMS.txt` from Releases.
2. Verify integrity:
   ```bash
   sha256sum -c SHA256SUMS.txt
   ```
3. Enable **Developer Options** and **USB Debugging** on the Pixel 7a (or allow installation from your browser/file manager on-device).
4. Install via ADB:
   ```bash
   adb install -r Antigravity-Mobile-debug.apk
   ```

## 12. Termux + Debian PRoot Setup Guide

Follow [`docs/setup.md`](docs/setup.md) and [`docs/termux-integration.md`](docs/termux-integration.md):

1. Launch **Termux** once to initialize `$HOME` and `$PREFIX`.
2. In **Antigravity Mobile -> Setup**, tap **Export / Copy Setup Script** (`TermuxSetupInstaller`) or run the commands manually from `docs/setup.md`.
3. Running the exported installer inside Termux configures `~/.termux/termux.properties` (`allow-external-apps=true`), reloads settings, installs `v1.1.0` wrapper/bootstrap/doctor scripts into `~/.antigravity-mobile/bin/` with SHA-256 verification and `chmod 700`, and executes an initial doctor check.
4. Grant `com.termux.permission.RUN_COMMAND` when prompted by Android.
5. Tap **Bootstrap Runtime** on the Setup screen to install `proot-distro`, `debian` (`aarch64`), required libraries, and run official CLI setup checks.

## 13. Authentication & First Antigravity CLI Launch

- Antigravity Mobile never injects or fakes credentials.
- If `agy-doctor.sh` reports `E_AUTH_REQUIRED`, tap **Open Termux**, enter Debian PRoot (`proot-distro login debian`), and complete the upstream interactive authentication flow required by the Antigravity CLI.
- Once Doctor returns `RUNTIME_READY`, return to Antigravity Mobile to start **Interactive Session** or **Headless Request** runs from the **Session** tab.

## 14. Verification Status & Honest Limits

| Check | Status | Evidence / Scope |
| :--- | :--- | :--- |
| `./gradlew :app:testDebugUnitTest` | **VERIFIED** | 41 unit & Robolectric tests passed, 0 failed, 0 skipped across 12 test suites |
| `./gradlew :app:lintDebug` | **VERIFIED** | 0 errors, 45 warnings (`app/build/reports/lint-results-debug.txt`) |
| `./gradlew :app:assembleDebug` | **VERIFIED** | `app-debug.apk` (`23,690,367` bytes), APK Signature Scheme v2 verified |
| Runtime script & asset parity | **VERIFIED** | `bash -n`, `python3 -m json.tool`, `cmp -s` match `runtime/` and `assets/runtime/` |
| Physical Pixel 7a Termux IPC & PRoot | **PENDING ON DEVICE** | Not verified in cloud build container (no ADB, emulator, or Termux runtime present) |
| Live Antigravity CLI download & auth | **PENDING ON DEVICE** | Requires live ARM64 Termux + Debian network & user authentication on Pixel 7a |
| Signed Release APK (`assembleRelease`) | **NOT CONFIGURED** | Production upload keystore credentials are not stored in this repository |

## 15. Testing & CI/CD

- **CI Workflow** (`.github/workflows/android-ci.yml`): Runs on pushes to `main`, pull requests to `main`, and manual `workflow_dispatch`. Validates runtime scripts/JSONs, runs all 41 unit/Robolectric tests, runs Android Lint, builds & verifies the Debug APK, and uploads APK + test/lint artifacts.
- **Release Workflow** (`.github/workflows/android-release.yml`): Runs on `v*` tags or manual `workflow_dispatch`. Publishes `Antigravity-Mobile-debug.apk`, `SHA256SUMS.txt`, and `release-manifest.json` (plus `Antigravity-Mobile-release.apk` only if signing secrets are configured in GitHub Repository Secrets).

## 16. Release Signing Instructions

Never commit `.jks`, `.keystore`, `.p12`, `.pem`, `.env`, or `signing.properties` files.

### Local Release Build
```bash
export KEYSTORE_PATH="/secure/path/to/my-upload-key.jks"
export STORE_PASSWORD="<store-password>"
export KEY_PASSWORD="<key-password>"
./gradlew :app:assembleRelease
```

### GitHub Actions Release Secrets
Configure under **Settings -> Secrets and variables -> Actions**:
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded upload keystore (`base64 -w0 my-upload-key.jks`)
- `STORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password (alias `"upload"`)

## 17. Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for symptom-to-fix resolution covering `E_TERMUX_MISSING`, `E_RUN_COMMAND_DENIED`, `E_EXTERNAL_APPS_DISABLED`, `E_WRAPPER_MISSING`, `E_WRAPPER_OUTDATED`, `E_LOW_STORAGE`, `E_TIMEOUT`, `E_CLI_ARCH_MISMATCH`, `E_AUTH_REQUIRED`, and `E_NETWORK_TLS`.

## 18. Security & Secrets Hygiene

- Report security concerns privately to the repository owner before opening public issues.
- Rotate any personal access tokens (`ghp_` / `github_pat_`) or API keys immediately if exposed locally; never embed them inside `.env.example`, Gradle files, or source code.

## 19. Documentation Index

- [`docs/setup.md`](docs/setup.md) — Step-by-step Pixel 7a, Termux, and script installation guide
- [`docs/termux-integration.md`](docs/termux-integration.md) — Android manifest, `RUN_COMMAND` intent extras, and callback receiver contract
- [`docs/security.md`](docs/security.md) — PRoot trust boundaries, `CommandValidator` rules, and `LogRedactor` protections
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — Error codes and recovery steps
- [`artifacts/README.md`](artifacts/README.md) — Checksums, release manifest, and verification guide

## 20. Roadmap / Remaining Real-Device Validation

- [ ] Install `Antigravity-Mobile-debug.apk` via ADB onto physical Google Pixel 7a
- [ ] Run exported Termux installer (`v1.1.0`) and grant `com.termux.permission.RUN_COMMAND`
- [ ] Execute live `Bootstrap` and `Doctor` inside ARM64 Termux + Debian PRoot
- [ ] Verify interactive Antigravity CLI login, headless request, MCP read-only tool call, and Workspace Sync round-trip on device
- [ ] Add production upload keystore secrets in GitHub Settings to enable signed `:app:assembleRelease` publishing
