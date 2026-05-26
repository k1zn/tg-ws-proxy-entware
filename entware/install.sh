#!/bin/sh
# Install tg-ws-proxy under Entware. Run as root on the router.
#
# Layout:
#   /opt/tg-ws-proxy/{proxy,utils}      <- code (only headless packages)
#   /opt/etc/tg-ws-proxy.conf           <- user config
#   /opt/etc/init.d/S99tgwsproxy        <- service
#   /opt/var/log/tg-ws-proxy.log        <- log
#
# Coexistence with zapret: this script does not touch iptables/nftables.
# zapret handles outbound DPI bypass on 443/80; we only open an inbound
# listener on $PORT (default 1443) for LAN clients. Keenetic's WAN
# firewall blocks incoming by default — no action needed for LAN-only.

set -e

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DST=/opt/tg-ws-proxy

echo "[*] Installing core deps from opkg..."
opkg update >/dev/null
opkg install python3 python3-light python3-asyncio python3-logging \
             python3-urllib python3-codecs python3-ctypes \
             libopenssl ca-certificates ca-bundle

echo "[*] Copying code to $DST ..."
mkdir -p "$DST"
cp -r "$SRC/proxy" "$DST/"

echo "[*] Smoke-test AES shim (cryptography or libcrypto fallback) ..."
cd "$DST"
python3 -c "
from proxy._aes import Cipher, algorithms, modes
c = Cipher(algorithms.AES(b'\x00'*32), modes.CTR(b'\x00'*16)).encryptor()
out = c.update(b'\x00'*64)
assert len(out) == 64
print('aes ok, first16:', out[:16].hex())
"

echo "[*] Installing init.d script ..."
cp "$SRC/entware/S99tgwsproxy" /opt/etc/init.d/S99tgwsproxy
chmod 0755 /opt/etc/init.d/S99tgwsproxy
if [ ! -f /opt/etc/tg-ws-proxy.conf ]; then
    cp "$SRC/entware/tg-ws-proxy.conf.example" /opt/etc/tg-ws-proxy.conf
    chmod 0644 /opt/etc/tg-ws-proxy.conf
fi
mkdir -p /opt/var/log

echo
echo "[+] Done. Edit /opt/etc/tg-ws-proxy.conf, then:"
echo "      /opt/etc/init.d/S99tgwsproxy start"
echo "    Logs: /opt/var/log/tg-ws-proxy.log"
echo "    Secret line will be appended to the conf on first start."
