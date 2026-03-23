#!/bin/bash

# firewall_save.sh  простой скрипт для сохранения правил nftables


SAVE_FILE="/etc/nftables.conf"


echo "Сохранение текущих правил nftables в $SAVE_FILE..."


# Сохраняем текущие правила nftables в файл
sudo nft list ruleset | sudo tee "$SAVE_FILE" > /dev/null


# Проверяем успешность выполнения
if [ $? -eq 0 ]; then
    echo "Правила успешно сохранены в $SAVE_FILE!"
else
    echo "Ошибка при сохранении правил!"
    exit 1
fi

echo "Скрипт firewall_save.sh завершён."

