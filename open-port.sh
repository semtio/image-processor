#!/bin/bash

################################################################################
# Script to open port 8000 in iptables firewall
# Run with: sudo bash open-port.sh
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PORT=${1:-8000}

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│   Открытие порта $PORT в firewall          │"
echo "└─────────────────────────────────────────────┘"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗${NC} Этот скрипт должен быть запущен с правами root"
   echo "Используйте: sudo bash open-port.sh"
   exit 1
fi

echo -e "${BLUE}ℹ${NC} Проверяем текущие правила iptables..."
echo ""

# Check current rules
if iptables -L INPUT -n | grep -q "dpt:$PORT"; then
    echo -e "${GREEN}✓${NC} Порт $PORT уже открыт в firewall"
    exit 0
fi

echo -e "${YELLOW}⚠${NC} Порт $PORT не найден в правилах firewall"
echo -e "${BLUE}ℹ${NC} Добавляем правило для порта $PORT..."
echo ""

# Add rule to allow port
iptables -I INPUT -p tcp --dport $PORT -j ACCEPT

# Check if rule was added
if iptables -L INPUT -n | grep -q "dpt:$PORT"; then
    echo -e "${GREEN}✓${NC} Порт $PORT успешно открыт!"
    echo ""
    echo "Новое правило:"
    iptables -L INPUT -n -v | grep "dpt:$PORT"
    echo ""

    # Save rules
    echo -e "${BLUE}ℹ${NC} Сохраняем правила iptables..."

    # Try different methods to save iptables rules
    if command -v iptables-save &> /dev/null; then
        if [ -f /etc/sysconfig/iptables ]; then
            # CentOS/RHEL
            iptables-save > /etc/sysconfig/iptables
            echo -e "${GREEN}✓${NC} Правила сохранены в /etc/sysconfig/iptables"
        elif [ -f /etc/iptables/rules.v4 ]; then
            # Debian/Ubuntu with iptables-persistent
            iptables-save > /etc/iptables/rules.v4
            echo -e "${GREEN}✓${NC} Правила сохранены в /etc/iptables/rules.v4"
        else
            echo -e "${YELLOW}⚠${NC} Правило добавлено, но не сохранено постоянно"
            echo "   Установите iptables-persistent или сохраните правила вручную"
        fi
    fi

    echo ""
    echo -e "${GREEN}✓${NC} Готово! Теперь порт $PORT доступен извне"
    echo ""
    echo "Проверьте доступ по адресу: http://185.209.20.80:$PORT"
    echo ""
else
    echo -e "${RED}✗${NC} Ошибка при добавлении правила"
    exit 1
fi
