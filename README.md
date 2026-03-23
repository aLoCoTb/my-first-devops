# my-first-devops

## Задание 1. Systemd-сервис с ограничениями

## Содержимое Systemd-Unit alive.service, для выполнения скрипта alive.py

```ini
[Unit]
Description=Alive service with resource limits
After=network.target

[Service]
User=nobody
ExecStart=/usr/bin/python3 /opt/alive/alive.py
Restart=on-failure
MemoryMax=50M
CPUQuota=20%

[Install]
WantedBy=multi-user.target
```
Описание параметров Unit
____________________________________________________________________________________________________________________________

- Description -  *описание сервиса*
- After=network.target -  сервис стартует после того, как сеть будет готова
- User=nobody - служба запускается от имени непривилегированного пользователя nobody
- ExecStart=/usr/bin/python3 /opt/alive/alive.py - команда для запуска скрипта
- Restart=on-failure - автоматически перезапускает сервис при нештатном завершении
- MemoryMax=50M - ограничение максимального использования памяти сервисом 50 мегабайт
- CPUQuota=20% - ограничивает использование CPU 20%
- WantedBy=multi-user.target - означает, что сервис будет запущен, когда система перейдёт в многопользовательский режим

## Задание 2. Настройка файрвола с помощью iptables/nftables

### Cкрипт firewall_rules.sh для применения правил

```
#!/bin/bash

FIREWALL_CONF="/etc/nftables.conf"

echo "Создание конфигурации nftables..."

cat > "$FIREWALL_CONF" << 'EOF'

#!/usr/sbin/nft -f

flush ruleset

table inet firewall {
    chain input {
        type filter hook input priority 0; policy drop;

        # Разрешаем loopback
        iif "lo" accept

        # Разрешаем уже установленные соединения
        ct state established,related accept

        # Разрешаем SSH только с доверенного IP
        tcp dport 22 ip saddr 192.168.26.1 accept

        # Разрешаем входящие на порт 8080 для перенаправления
        tcp dport 8080 accept

        # Разрешаем прямой доступ к порту 80
        tcp dport 80 accept
    }

    chain output {
        type filter hook output priority 0; policy accept;
        accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }
}

table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100;
        tcp dport 8080 redirect to :80
    }
}


EOF

# Применяем правила
nft -f "$FIREWALL_CONF"

echo "Правила nftables успешно применены!"

```

### Описание правил для настройки

____________________________________________________________________________________________________________________________

**nft flush ruleset** - Полностью очищает все существующие правила брандмауэра. Гарантирует, что новые правила применяются без конфликтов со старыми

#### Правила для входящих пакетов

type filter hook input priority filter; policy drop;
запрещает все входящие соединения

iif "lo" accept
разрешает все входящие пакеты, пришедшие через loopbackинтерфейс (необходимо для работы локальных служб)

ct state established,related accept
разрешает входящие пакеты для уже установленных соединений

tcp dport 22 ip saddr 192.168.26.1 accept
разрешает SSHподключения (порт 22/TCP) только с IPадреса

tcp dport 8080 accept
разрешает входящие TCPсоединения на порт 8080 с любого IPадреса

tcp dport 80 accept
разрешает HTTPтрафик (порт 80/TCP) с любого IPадреса


#### Правила для исходящих пакетов

type filter hook output priority filter; policy accept;
разрешает все исходящие соединения

type filter hook forward priority filter; policy drop;
блокирует все транзитные пакеты

#### Правила NAT

type nat hook prerouting priority dstnat; policy accept;
определяет цепь для правил DNAT (преобразования адреса назначения)

tcp dport 8080 redirect to :80
перенаправляет входящий трафик с порта 8080 на порт 80
