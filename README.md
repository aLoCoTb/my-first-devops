# my-first-devops

# Задание 1. Systemd-сервис с ограничениями

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
Описание параметров для работы Unit (alive.service)
____________________________________________________________________________________________________________________________

- **Description** - *описание сервиса*
- **After=network.target** -  *сервис стартует после того, как сеть будет готова*
- **User=nobody** - *служба запускается от имени непривилегированного пользователя nobody*
- **ExecStart=/usr/bin/python3 /opt/alive/alive.py** - *команда для запуска скрипта*
- **Restart=on-failure** - *автоматически перезапускает сервис при нештатном завершении*
- **MemoryMax=50M** - *ограничение максимального использования памяти сервисом 50 мегабайт*
- **CPUQuota=20%** - *ограничивает использование CPU 20%*
- **WantedBy=multi-user.target** - *означает, что сервис будет запущен, когда система перейдёт в многопользовательский режим*
____________________________________________________________________________________________________________________________

## Взаимодействие с сервисом alive.service (stop/start/status)

<img width="600" height="500" alt="Image" src="https://github.com/user-attachments/assets/512cd5f9-269d-4376-bbf3-63635b3888ba" />

## Вывод journalctl -u alive.service

<img width="600" height="500" alt="Image" src="https://github.com/user-attachments/assets/193d273d-b892-43d1-bb0c-31c1ad00de2b" />

# Задание 2. Настройка файрвола с помощью iptables/nftables

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

`nft flush ruleset` - Полностью очищает все существующие правила брандмауэра. Гарантирует, что новые правила применяются без конфликтов со старыми

### 1. Правила для входящих пакетов

`type filter hook input priority filter; policy drop;` - запрещает все входящие соединения

`iif "lo" accept` - разрешает все входящие пакеты, пришедшие через loopbackинтерфейс (необходимо для работы локальных служб)

`ct state established,related accept` - разрешает входящие пакеты для уже установленных соединений

`tcp dport 22 ip saddr 192.168.26.1 accept` - разрешает SSH подключения (порт 22/TCP) только с IP адреса

`tcp dport 8080 accept` - разрешает входящие соединения на порт 8080 с любого IPадреса

`tcp dport 80 accept` - разрешает входящие соединение на порт 80 с любого IPадреса

---

### 2. Правила для исходящих пакетов

`type filter hook output priority filter; policy accept;` - разрешает все исходящие соединения

`type filter hook forward priority filter; policy drop;` - блокирует все транзитные пакеты

---

### 3.Правила NAT

`type nat hook prerouting priority dstnat; policy accept;` - определяет цепь для правил DNAT (преобразования адреса назначения)

`tcp dport 8080 redirect to :80` - перенаправляет входящий трафик с порта 8080 на порт 80

---

## Проверка правил nftable

<img width="477" height="154" alt="Image" src="https://github.com/user-attachments/assets/e8e570f1-7162-46b1-8141-d0b5bd931646" />

*ICMP запрещен за счет правила для входящих соединений `type filter hook input priority filter; policy drop;`*

---

<img width="600" height="500" alt="Image" src="https://github.com/user-attachments/assets/43c5258e-d397-429c-8319-ce29529c13d1" />

*Редирект с помощью правила `tcp dport 8080 redirect to :80`*

---


<img width="390" height="120" alt="Image" src="https://github.com/user-attachments/assets/b15cad03-3989-4562-bec6-d2ec07cc9be1" />
<img width="390" height="120" alt="Image" src="https://github.com/user-attachments/assets/321ba6eb-4a0c-4757-be60-2819955dc9a2" />

*Проверка SSH подключения, доступ осуществляется только с 192.168.26.1 `tcp dport 22 ip saddr 192.168.26.1 accept`*

---

# Задание 3. Работа с LVM

## Расширяем место до 20Gb

<img width="504" height="131" alt="Image" src="https://github.com/user-attachments/assets/0565dd9f-4661-4e76-8fae-c6c50f7b2054" />

*Смотрим изначальную карту диска*

1. **Отключаем VM и расширяем диск до 20Gb**
<img width="200" height="90" alt="Image" src="https://github.com/user-attachments/assets/9f2645f9-6815-403c-9c28-6906ad28a670" />
<img width="200" height="90" alt="Image" src="https://github.com/user-attachments/assets/b9eb1d2c-e717-414a-8c3c-2d4993544621" />

<img width="500" height="150" alt="Image" src="https://github.com/user-attachments/assets/b36c56ee-ddb0-4068-85ef-d6684044f191" />

*Карта диска после добавления*

2. **C помощью `fdisk /dev/sda/` создаем новый раздел**

3. **Объединяем размеры**
   `sudo lvextend -l +100%FREE /dev/debiantest-vg/root`
   `sudo xfs_growfs /dev/mapper/debiantest--vg-root`

4. **Проверяем размер LVM**

<img width="512" height="182" alt="Image" src="https://github.com/user-attachments/assets/4dfddaaa-c94a-48d0-91f1-0867ad9e23ce" />
