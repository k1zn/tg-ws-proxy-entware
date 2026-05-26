# tg-ws-proxy (Entware fork)

Если хотите поддержать оригинального автора — его контакты в [апстрим-репозитории](https://github.com/Flowseal/tg-ws-proxy).

Данный форк позволяет запустить локальный tg-ws-proxy на вашем роутере, используя Entware.

## Подготовка роутера

Разверните Entware на USB-флешке — см. официальный гайд Keenetic:
**[Установка репозитория Entware на USB-накопитель](https://support.keenetic.ru/ultra/kn-1811/ru/20980.html)**.

## Установка

```sh
# с компа — залить исходники на роутер
scp -O -r tg-ws-proxy root@192.168.1.1:/tmp/

# на роутере
ssh root@192.168.1.1
cd /tmp/tg-ws-proxy
sh entware/install.sh
```

## Настройка

```sh
nano /opt/etc/tg-ws-proxy.conf
```
или
```sh
vi /opt/etc/tg-ws-proxy.conf
```

```
HOST=0.0.0.0
PORT=1443
SECRET=
DC_IPS="2:149.154.167.220 4:149.154.167.220"
POOL_SIZE=1
FAKE_TLS_DOMAIN=
EXTRA_ARGS=
```

`SECRET` пустой = автогенерация при первом запуске.

## Запуск

```sh
/opt/etc/init.d/S99tgwsproxy start
tail -f /opt/var/log/tg-ws-proxy.log
```

В логе появится ссылка `tg://proxy?server=...&port=...&secret=...` — откройте её в Telegram.

Скрипт стартует автоматически после ребута роутера.

## Управление

```sh
/opt/etc/init.d/S99tgwsproxy start|stop|restart|check
```

## Удаление

```sh
/opt/etc/init.d/S99tgwsproxy stop
rm -f /opt/etc/init.d/S99tgwsproxy /opt/etc/tg-ws-proxy.conf
rm -rf /opt/tg-ws-proxy /opt/var/log/tg-ws-proxy.log*
```
