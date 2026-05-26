# tg-ws-proxy on Entware (Keenetic / OpenWrt-style routers)

Headless install. No GUI deps (`pyperclip`, `customtkinter`, `pystray`,
`Pillow`, `rumps` are skipped). The `cryptography` package is **not**
installed — `proxy/_aes.py` uses the router's system `libcrypto` via
ctypes. If `cryptography` happens to be importable it is preferred.

## Install

Copy the repo onto the router (scp / git / usb), then:

```sh
cd /tmp/tg-ws-proxy-main      # wherever you put it
sh entware/install.sh
vi /opt/etc/tg-ws-proxy.conf  # set PORT / FAKE_TLS_DOMAIN if desired
/opt/etc/init.d/S99tgwsproxy start
tail -f /opt/var/log/tg-ws-proxy.log
```

The `tg://proxy?...` link prints into the log on startup.

## Memory / CPU notes (512 MB router)

* `POOL_SIZE=1` in the conf — keeps idle WS connections to 1 per DC.
  Default upstream is 4; on a router that's wasted RAM. Bump to 2 if
  you have many simultaneous Telegram clients.
* AES-CTR runs through OpenSSL's native EVP, so it's hardware-accelerated
  on aarch64 boxes that support ARMv8 crypto extensions.
* Expect ~20–40 MB RSS for python3 with a handful of clients.

## Coexistence with zapret

`zapret` works at netfilter level (NFQUEUE on OUTPUT, ports 80/443). 
`tg-ws-proxy` is a userspace listener on `PORT` (1443 by default) that
makes outbound WSS connections to `kws*.web.telegram.org:443`. The
outbound side passes through whatever zapret rules exist — which is
desirable, not a conflict.

This install script does **not** touch iptables/nftables, so it can't
clobber zapret's rules.

By default the proxy is LAN-only: Keenetic's WAN firewall blocks
incoming connections, so binding to `0.0.0.0` just means "reachable
from every LAN client", not "exposed to the internet". To make it
strictly LAN-bound at the socket level, set `HOST=<router-lan-ip>` in
the conf instead of `0.0.0.0`.

## Uninstall

```sh
/opt/etc/init.d/S99tgwsproxy stop
rm -f /opt/etc/init.d/S99tgwsproxy /opt/etc/tg-ws-proxy.conf
rm -rf /opt/tg-ws-proxy /opt/var/log/tg-ws-proxy.log*
```
