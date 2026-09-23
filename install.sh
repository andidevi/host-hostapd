#!/bin/sh
# Install hostapd + systemd files from this repo.
# Usage: sudo ./install.sh [--no-enable] [--no-reload]
set -eu

SRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

HOSTAPD_SRC="$SRC_DIR/hostapd/wlp3s0.conf"
SERVICE_SRC="$SRC_DIR/systemd/system/hostapd-wlp3s0.service"
SSID_EXAMPLE="$SRC_DIR/hostapd/values/ssid.example"
PASS_EXAMPLE="$SRC_DIR/hostapd/values/password.example"

HOSTAPD_DST="/srv/hostapd/wlp3s0.conf"
SERVICE_DST="/etc/systemd/system/hostapd-wlp3s0.service"
SSID_DST="/srv/hostapd/values/ssid"
PASS_DST="/srv/hostapd/values/password"

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

for f in "$HOSTAPD_SRC" "$SERVICE_SRC" "$SSID_EXAMPLE" "$PASS_EXAMPLE"; do
  [ -f "$f" ] || { echo "Missing source file: $f" >&2; exit 1; }
done

# hostapd base config -> /srv/hostapd (geheimnisfrei, 0644 reicht)
install -D -m 0644 "$HOSTAPD_SRC" "$HOSTAPD_DST"

# Beispielwerte nur installieren, wenn am Ziel noch nichts liegt (0600, Klartext)
if [ -e "$SSID_DST" ]; then
  echo "Keeping existing $SSID_DST"
else
  install -D -m 0600 "$SSID_EXAMPLE" "$SSID_DST"
fi
if [ -e "$PASS_DST" ]; then
  echo "Keeping existing $PASS_DST"
else
  install -D -m 0600 "$PASS_EXAMPLE" "$PASS_DST"
fi

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
echo "  $SSID_DST (only if new)"
echo "  $PASS_DST (only if new)"
