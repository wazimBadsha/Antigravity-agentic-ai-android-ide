# Termux RUN_COMMAND Integration Specification

## Android Manifest Declarations
`app/src/main/AndroidManifest.xml` declares:
- `<uses-permission android:name="com.termux.permission.RUN_COMMAND" />`
- `<queries>` visibility for `com.termux`, `com.termux.x11`, `com.termux.api`, and `com.termux.RUN_COMMAND`
- Non-exported receiver `com.example.termux.TermuxCommandResultReceiver`

## Intent Contract (`TermuxRunCommandAdapter`)
- **Action**: `com.termux.RUN_COMMAND`
- **Component**: `com.termux` / `com.termux.app.RunCommandService`
- **Extras**:
  - `com.termux.RUN_COMMAND_PATH`: `/data/data/com.termux/files/home/.antigravity-mobile/bin/agy-wrapper.sh`
  - `com.termux.RUN_COMMAND_ARGUMENTS`: validated `String[]` array
  - `com.termux.RUN_COMMAND_WORKDIR`: `/data/data/com.termux/files/home`
  - `com.termux.RUN_COMMAND_BACKGROUND`: `Boolean` (`true` for doctor/bootstrap/headless/stop/recover/reset; `false` for interactive terminal launch)
  - `com.termux.RUN_COMMAND_SESSION_ACTION`: `"1"` (background) or `"0"` (switch to new session & open Termux)
  - `com.termux.RUN_COMMAND_PENDING_INTENT`: explicit `PendingIntent.getBroadcast(...)` (`FLAG_MUTABLE` on Android 12+ so Termux can populate `EXTRA_PLUGIN_RESULT_BUNDLE`)

## Callback Bundle Parsing
`TermuxCommandResultReceiver` extracts bundle `"result"` (`stdout`, `stderr`, `exitCode`, `err`, `errmsg`), runs `LogRedactor`, and dispatches `TermuxCommandCallbackResult` to `TermuxResultBus`.
