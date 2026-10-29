# host-hostapd
simple hostapd sae config with systemd for systems without networkmanager

## dmesg watchdog
Some wifi hardware wedges its key table; the kernel then logs
`failed to remove key .* from hardware` and the AP stops serving clients.
`bin/hostapd-dmesg-watchdog` follows the kernel ring buffer (`dmesg --follow-new`,
new messages only) and runs `systemctl restart` on the hostapd unit when that
message appears. It lives and dies with `hostapd-wlp3s0.service` (`Wants=`/`PartOf=`)
and a 10 s cooldown collapses message bursts into a single restart.

Test trigger — careful, this really restarts the running AP:

    echo "wlp3s0: failed to remove key (1, ff:ff:ff:ff:ff:ff) from hardware (-110)" | sudo tee /dev/kmsg
