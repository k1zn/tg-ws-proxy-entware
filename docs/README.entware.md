# Entware (Keenetic / OpenWrt-style routers)

Headless-сборка tg-ws-proxy под Entware на USB-флешке (роутеры Keenetic,
OpenWrt и подобные).

Без GUI-зависимостей: `pyperclip`, `customtkinter`, `pystray`, `Pillow`,
`rumps` не ставятся. `cryptography` тоже не ставится — `proxy/_aes.py`
автоматически использует системный `libcrypto` через `ctypes`, что
избавляет от компиляции Rust на роутере. Если `cryptography` всё же
доступен в системе, он используется.

## Подготовка роутера

Развернуть Entware на USB-флешке — см. официальный гайд Keenetic:
**[Установка репозитория Entware на USB-накопитель](https://support.keenetic.ru/ultra/kn-1811/ru/20980.html)**.
После этого должен работать `ssh root@<ip-роутера>` и команда `opkg` в
шелле.

## Установка

```sh
# с компа — залить исходники на роутер
scp -O -r tg-ws-proxy root@192.168.1.1:/tmp/

# на роутере
ssh root@192.168.1.1
cd /tmp/tg-ws-proxy
sh entware/install.sh
```

Скрипт:
- ставит `python3` и `libopenssl` через opkg;
- копирует пакет `proxy/` в `/opt/tg-ws-proxy/`;
- прогоняет smoke-тест AES через системный libcrypto;
- кладёт init.d-скрипт `/opt/etc/init.d/S99tgwsproxy`;
- создаёт `/opt/etc/tg-ws-proxy.conf` (повторный запуск его не
  перезатирает).

## Настройка

```sh
nano /opt/etc/tg-ws-proxy.conf     # или vi, если nano не стоит
```

```
HOST=0.0.0.0          # слушать на всех интерфейсах LAN
PORT=1443
SECRET=               # пусто = автогенерация при первом запуске
DC_IPS="2:149.154.167.220 4:149.154.167.220"
POOL_SIZE=1           # на 512 МБ RAM хватит
FAKE_TLS_DOMAIN=      # опционально, например www.cloudflare.com
EXTRA_ARGS=
```

`HOST=0.0.0.0` ≠ «открыто наружу»: фаервол Keenetic по умолчанию режет
входящие из WAN. Если хочется строго bind на LAN-интерфейс — поставь
`HOST=192.168.1.1` (LAN-IP роутера).

## Запуск

```sh
/opt/etc/init.d/S99tgwsproxy start
tail -f /opt/var/log/tg-ws-proxy.log
```

На старте в лог печатается ссылка `tg://proxy?server=...&port=...&secret=...`
— кликаешь её в Telegram → прокси добавлен.

Скрипт назван `S99`, поэтому стартует автоматически после ребута
роутера.

## Управление

```sh
/opt/etc/init.d/S99tgwsproxy start|stop|restart|check
tail -f /opt/var/log/tg-ws-proxy.log
ps w | grep tg_ws_proxy
netstat -tlnp | grep :1443
```

## Память / CPU

- `POOL_SIZE=1` в конфиге держит идл-пул WS-коннектов на 1 на DC. По
  умолчанию в апстриме 4 — на роутере это лишний RAM.
- AES-CTR идёт через нативный OpenSSL EVP, hardware-ускоряется на
  aarch64-роутерах с ARMv8 crypto extensions.
- Ожидаемый RSS — 20–40 МБ при паре клиентов.

## Сосуществование с zapret

`zapret` работает через NFQUEUE на исходящих 443/80 для обхода DPI.
`tg-ws-proxy` слушает на `PORT` (1443) и ходит наружу на
`kws*.web.telegram.org:443` — этот трафик как раз проходит через
zapret-правила, что и нужно. Установщик не трогает iptables/nftables,
поэтому конфликта с zapret не будет.

## Удаление

```sh
/opt/etc/init.d/S99tgwsproxy stop
rm -f /opt/etc/init.d/S99tgwsproxy /opt/etc/tg-ws-proxy.conf
rm -rf /opt/tg-ws-proxy /opt/var/log/tg-ws-proxy.log*
```
