#!/data/data/com.termux/files/usr/bin/bash
# Antigravity Mobile Idempotent Bootstrap Script (v1.1.0)
# Installs PRoot-Distro + Debian ARM64 userspace, official Antigravity CLI (agy), and provenance manifest.
set -euo pipefail

CHANNEL="stable"
PINNED_VERSION="latest-verified"
DISTRO_ALIAS="debian"
BASE_DIR="${HOME}/.antigravity-mobile"
STATE_DIR="${BASE_DIR}/state"
MANIFEST_OUT="${STATE_DIR}/provenance-manifest.json"
OFFICIAL_INSTALLER_URL="https://antigravity.google/cli/install.sh"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --channel) CHANNEL="${2:-stable}"; shift 2 ;;
    --version) PINNED_VERSION="${2:-latest-verified}"; shift 2 ;;
    *) echo "Unknown bootstrap flag: $1" >&2; exit 2 ;;
  esac
done

ARCH="$(uname -m)"
if [ "${ARCH}" != "aarch64" ] && [ "${ARCH}" != "arm64" ]; then
  echo "ERROR: Unsupported architecture '${ARCH}'. Pixel 7a / ARM64 (aarch64) required." >&2
  exit 3
fi

# Verify free storage (>= 1024 MiB recommended for Debian rootfs + CLI)
FREE_MB="$(df -Pm "${HOME}" | awk 'NR==2 {print $4}')"
if [ "${FREE_MB:-0}" -lt 1024 ]; then
  echo "WARN: Less than 1024 MiB free in Termux home (${FREE_MB:-0} MiB available)." >&2
fi

# Idempotent Termux base prerequisites
pkg update -y
pkg install -y proot-distro curl ca-certificates openssl file git

if ! proot-distro list 2>/dev/null | grep -Eq "(^|[[:space:]])${DISTRO_ALIAS}([[:space:]]|$)"; then
  echo "Installing Debian ARM64 PRoot rootfs..."
  proot-distro install "${DISTRO_ALIAS}"
else
  echo "Debian ARM64 PRoot rootfs already present (idempotent skip)."
fi

echo "Verifying Debian ARM64 baseline libraries, DNS/HTTPS, git, and ca-certificates..."
proot-distro login "${DISTRO_ALIAS}" -- bash -lc '
  set -euo pipefail
  DEBIAN_ARCH="$(dpkg --print-architecture)"
  echo "Debian dpkg architecture: ${DEBIAN_ARCH}"
  if [ "${DEBIAN_ARCH}" != "arm64" ] && [ "${DEBIAN_ARCH}" != "aarch64" ]; then
    echo "ERROR: Expected arm64 Debian userspace, got ${DEBIAN_ARCH}" >&2
    exit 3
  fi
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl file git libstdc++6
  curl -fsSI --max-time 12 https://deb.debian.org >/dev/null
'

echo "Installing official Antigravity CLI (agy) inside Debian PRoot (channel=${CHANNEL}, pin=${PINNED_VERSION})..."
proot-distro login "${DISTRO_ALIAS}" -- env AGY_INSTALL_URL="${OFFICIAL_INSTALLER_URL}" AGY_CHANNEL="${CHANNEL}" AGY_PIN="${PINNED_VERSION}" bash -lc '
  set -euo pipefail
  export PATH="$HOME/.local/bin:$PATH"
  if ! grep -q ".local/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
  fi
  if command -v agy >/dev/null 2>&1 || [ -x "$HOME/.local/bin/agy" ]; then
    echo "Antigravity CLI already installed; verifying latest status via official installer..."
  fi
  curl -fsSL "$AGY_INSTALL_URL" | bash
  RESOLVED_CLI="$(command -v agy 2>/dev/null || ([ -x "$HOME/.local/bin/agy" ] && echo "$HOME/.local/bin/agy") || command -v antigravity 2>/dev/null || true)"
  if [ -z "${RESOLVED_CLI}" ]; then
    echo "ERROR: Official Antigravity CLI binary (agy) was not found after installation." >&2
    exit 12
  fi
  echo "Resolved Antigravity CLI path: ${RESOLVED_CLI}"
  "${RESOLVED_CLI}" --version || true
'

mkdir -p "${STATE_DIR}" "$(dirname "${MANIFEST_OUT}")"
CLI_BIN="$(proot-distro login "${DISTRO_ALIAS}" -- bash -lc 'export PATH="$HOME/.local/bin:$PATH"; command -v agy 2>/dev/null || ([ -x "$HOME/.local/bin/agy" ] && echo "$HOME/.local/bin/agy") || command -v antigravity 2>/dev/null || true')"
CLI_ARCH="unverified"
CLI_VER="unverified"
CLI_SHA="not-recorded"
if [ -n "${CLI_BIN}" ]; then
  CLI_ARCH="$(proot-distro login "${DISTRO_ALIAS}" -- bash -lc "file -b '${CLI_BIN}' 2>/dev/null | grep -oiE 'aarch64|arm64' | head -n1 || uname -m")"
  CLI_VER="$(proot-distro login "${DISTRO_ALIAS}" -- bash -lc "export PATH=\"\$HOME/.local/bin:\$PATH\"; '${CLI_BIN}' --version 2>/dev/null | head -n1 || echo unknown")"
  CLI_SHA="$(proot-distro login "${DISTRO_ALIAS}" -- bash -lc "sha256sum '${CLI_BIN}' 2>/dev/null | awk '{print \$1}' || echo not-recorded")"
fi

if [ -n "${CLI_BIN}" ] && [ "${CLI_ARCH}" != "aarch64" ] && [ "${CLI_ARCH}" != "arm64" ]; then
  echo "ERROR: Installed Antigravity CLI architecture '${CLI_ARCH}' is not ARM64." >&2
  exit 14
fi

DEBIAN_CODENAME="$(proot-distro login "${DISTRO_ALIAS}" -- bash -lc 'grep -E "^VERSION_CODENAME=" /etc/os-release 2>/dev/null | cut -d= -f2 || echo debian')"
PROOT_VER="$(proot-distro --version 2>/dev/null | head -n1 || echo installed)"

cat > "${MANIFEST_OUT}" <<EOF
{
  "desktop": {
    "product": "antigravity-desktop",
    "version": "tracked-separately",
    "architecture": "arm64",
    "status": "optional-research"
  },
  "cli": {
    "product": "antigravity-cli",
    "binary_path": "${CLI_BIN}",
    "version": "${CLI_VER}",
    "architecture": "${CLI_ARCH}",
    "source": "official-upstream-${CHANNEL}",
    "installer_url": "${OFFICIAL_INSTALLER_URL}",
    "sha256": "${CLI_SHA}"
  },
  "runtime": {
    "termux": "${TERMUX_VERSION:-unknown}",
    "proot_distro": "${PROOT_VER}",
    "debian": "${DEBIAN_CODENAME}",
    "architecture": "${ARCH}",
    "free_storage_mb": ${FREE_MB:-0}
  }
}
EOF

echo "Bootstrap finished cleanly. Provenance written to ${MANIFEST_OUT}."
echo "Next step (user action if unauthenticated): Open Termux and run 'proot-distro login debian -- \$HOME/.local/bin/agy' to complete Google OAuth sign-in."
