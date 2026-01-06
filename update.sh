#!/bin/bash

################################################################################
# Скрипт автоматического обновления на сервере
# Использование: bash update.sh
################################################################################

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/root/image-processor"

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│   Обновление Image Processor                │"
echo "└─────────────────────────────────────────────┘"
echo ""

# Проверка директории
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Директория проекта не найдена: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Остановить сервер
echo -e "${BLUE}ℹ${NC} Останавливаем сервер..."
if systemctl is-active --quiet image-processor; then
    systemctl stop image-processor
    echo -e "${GREEN}✓${NC} Сервис остановлен"
else
    # Остановить вручную запущенный процесс
    PHP_PID=$(ps aux | grep "php -S.*8000" | grep -v grep | awk '{print $2}')
    if [ ! -z "$PHP_PID" ]; then
        kill $PHP_PID
        echo -e "${GREEN}✓${NC} Процесс PHP остановлен (PID: $PHP_PID)"
    else
        echo -e "${BLUE}ℹ${NC} Сервер не запущен"
    fi
fi

# Получить обновления
echo -e "${BLUE}ℹ${NC} Получаем обновления с GitHub..."
git pull origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Обновления получены успешно"
else
    echo -e "${YELLOW}⚠${NC} Ошибка при получении обновлений"
fi

# Запустить сервер
echo -e "${BLUE}ℹ${NC} Запускаем сервер..."
if systemctl list-unit-files | grep -q image-processor; then
    systemctl start image-processor
    echo -e "${GREEN}✓${NC} Сервис запущен"
else
    # Запустить вручную в фоне
    nohup bash run.sh > /dev/null 2>&1 &
    echo -e "${GREEN}✓${NC} Сервер запущен в фоновом режиме"
fi

echo ""
echo -e "${GREEN}✓${NC} Обновление завершено!"
echo ""
echo "Проверьте работу: http://185.209.20.80:8000/"
echo ""
