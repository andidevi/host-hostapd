#!/bin/sh
# Install hostapd + systemd files from this repo.
# Usage: sudo ./install.sh [--no-enable] [--no-reload]
set -eu

SRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

HOSTAPD_SRC="$SRC_DIR/hostapd/wlp3s0.conf"
SERVICE_SRC="$SRC_DIR/systemd/system/hostapd-wlp3s0.service"

HOSTAPD_DST="/srv/hostapd/wlp3s0.conf"
SERVICE_DST="/etc/systemd/system/hostapd-wlp3s0.service"

ENABLE=1
RELOAD=1
for arg in "$@"; do
  case "$arg" in
    --no-enable) ENABLE=0 ;;
    --no-reload) RELOAD=0 ;;
    -h|--help)
      echo "Usage: $0 [--no-enable] [--no-reload]"
      exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

for f in "$HOSTAPD_SRC" "$SERVICE_SRC"; do
  [ -f "$f" ] || { echo "Missing source file: $f" >&2; exit 1; }
done

# hostapd configs -> /srv/hostapd (0600: contains PSK/password)
install -D -m 0600 "$HOSTAPD_SRC" "$HOSTAPD_DST"

# systemd unit -> /etc/systemd/system (0644)
install -D -m 0644 "$SERVICE_SRC" "$SERVICE_DST"

# Ensure runtime dir for ctrl_interface exists at boot (no tmpfiles needed; hostapd creates /run/hostapd)

if [ "$RELOAD" -eq 1 ]; then
  systemctl daemon-reload
fi

if [ "$ENABLE" -eq 1 ]; then
  # Don't fight other supplicants on the AP interface
  systemctl disable --now wpa_supplicant@wlp3s0.service 2>/dev/null || true
  systemctl enable --now hostapd-wlp3s0.service
else
  echo "Installed without enabling. Run: systemctl enable --now hostapd-wlp3s0.service"
fi

echo "Installed:"
echo "  $HOSTAPD_DST"
echo "  $SERVICE_DST"
