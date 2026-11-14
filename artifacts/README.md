# Antigravity Mobile — Release Artifacts & Verification

APK binaries (`*.apk`) are excluded from normal Git source commits via `.gitignore` and distributed exclusively through **GitHub Releases** and **GitHub Actions CI build artifacts**.

## Current Build Metadata

| Property | Value |
| :--- | :--- |
| **Application ID** | `com.aistudio.antigravitymobile.wqkvb` |
| **Version** | `1.0` (`versionCode: 1`) |
| **SDK Levels** | `minSdk 24` / `targetSdk 36` / `compileSdk 36.1` |
| **Debug APK Filename** | `Antigravity-Mobile-debug.apk` |
| **Debug APK Size** | `23,690,367` bytes (~22.6 MiB / 23.7 MB decimal) |
| **Debug APK SHA-256** | `b9615280fb9bb722f5df4eb23ea2e91b0da86a74f4aa2f98861554c1c38473e9` |
| **Signing Status (Debug)** | Verified using APK Signature Scheme v2 (`debugConfig`) |
| **Release APK Status** | **NOT AVAILABLE — PRODUCTION SIGNING CREDENTIALS NOT CONFIGURED** |

## Verification Boundaries

- **Cloud Build Container Verified**:
  - `./gradlew :app:testDebugUnitTest`: **41 passed, 0 failed, 0 skipped**
  - `./gradlew :app:lintDebug`: **0 errors, 45 warnings**
  - `./gradlew :app:assembleDebug`: **BUILD SUCCESSFUL**
  - Runtime shell scripts (`agy-bootstrap.sh`, `agy-wrapper.sh`, `agy-doctor.sh`) syntax-checked (`bash -n`) and byte-identical to bundled assets (`cmp -s`).
- **Physical Pixel 7a Device Pending (NOT VERIFIED in cloud sandbox)**:
  - Live `com.termux.RUN_COMMAND` IPC round-trip
  - PRoot Debian ARM64 bootstrap & upstream Antigravity CLI download/auth
  - End-to-end interactive/headless agent session & physical APK installation

## Downloading & Verifying the APK

1. Download `Antigravity-Mobile-debug.apk` and `SHA256SUMS.txt` from [GitHub Releases](https://github.com/wazimBadSha/Antigravity-agentic-ai-android-ide/releases) or the latest successful **Android CI** workflow run.
2. Verify the SHA-256 checksum locally before installing:
   ```bash
   sha256sum -c SHA256SUMS.txt
   ```
3. Install onto a Google Pixel 7a over ADB:
   ```bash
   adb install -r Antigravity-Mobile-debug.apk
   ```
