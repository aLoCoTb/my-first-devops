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
