# Antigravity Mobile — Security & Trust Boundaries

## 1. PRoot Security Boundary
PRoot (`proot-distro`) is a **user-space compatibility layer**, not a kernel sandbox. It does not provide Linux kernel namespaces, cgroups, real root, or process/network isolation.

- **Default Agent Policy**: Conservative request-review / explicit permission posture.
- **`--no-sandbox` Prohibition**: `SecurityPolicy` and wrapper scripts strictly prohibit passing `--no-sandbox` as a production workaround.

## 2. IPC & Command Injection Prevention
- The Android APK never opens Termux's private filesystem (`/data/data/com.termux/...`) directly.
- All IPC goes exclusively through `com.termux.RUN_COMMAND` targeting `com.termux.app.RunCommandService`.
- `CommandValidator` enforces an explicit allowlist of operations (`doctor`, `bootstrap`, `start-interactive`, `start-headless`, `stop`, `recover`, `reset`, `check-mcp`, `workspace-exec`, `workspace-sync-file`, `workspace-git`, `workspace-build`) on a single fixed entrypoint (`~/.antigravity-mobile/bin/agy-wrapper.sh`) and rejects shell metacharacters (`;`, `|`, `&`, `$`, `` ` ``, redirection, newlines, and `..` path traversal).

## 3. Secret Protection & Log Redaction
- `LogRedactor` strips bearer tokens, `Authorization` headers, cookies (`Cookie` / `Set-Cookie`), API keys (`AIza...`, `sk-...`, `ghp_...`, `github_pat_...`, `ck_`/`cs_`), URL credentials, and email PII before storing or exporting diagnostic logs.
- No WooCommerce admin secrets or payment credentials are stored in the APK, DataStore preferences, Room DB, or Termux environment.

## 4. Optional Commerce Boundary
Optional Commerce (`commerce-mcp` -> `commerce-api`) stays disabled by default and gated outside core APK readiness. Financial checkout requires server-side recalculation, a short-lived single-use confirmation token, explicit trusted UI confirmation, and server-side revalidation with idempotency.
