#!/bin/bash

# Quick start script for Image Processor
# Run from the image-processor directory: bash run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables if they exist
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Configuration file path
CONFIG_FILE="$SCRIPT_DIR/config/config.php"
ENV_FILE="$SCRIPT_DIR/.env"

# Function to read IP from config
get_saved_ip() {
    if [ -f "$ENV_FILE" ]; then
        saved_ip=$(grep "^SERVER_IP=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'")
        echo "$saved_ip"
    fi
}

# Function to save IP and PORT to .env
save_config() {
    local ip="$1"
    local port="$2"
    if [ -f "$ENV_FILE" ]; then
        # Update existing .env
        sed -i.bak "s/^SERVER_IP=.*/SERVER_IP=$ip/" "$ENV_FILE"
        sed -i.bak "s/^SERVER_PORT=.*/SERVER_PORT=$port/" "$ENV_FILE"
    else
        # Create new .env
        echo "SERVER_IP=$ip" > "$ENV_FILE"
        echo "SERVER_PORT=$port" >> "$ENV_FILE"
    fi
}

# Function to read PORT from .env
get_saved_port() {
    if [ -f "$ENV_FILE" ]; then
        saved_port=$(grep "^SERVER_PORT=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'")
        echo "$saved_port"
    fi
}

# Check if IP and PORT are configured
SAVED_IP=$(get_saved_ip)
SAVED_PORT=$(get_saved_port)

if [ -z "$SAVED_IP" ] || [ "$SAVED_IP" = "0.0.0.0" ] || [ -z "$SAVED_PORT" ]; then
    echo ""
    echo "┌─────────────────────────────────────────────┐"
    echo "│   Image Processor - Setup                  │"
    echo "└─────────────────────────────────────────────┘"
    echo ""
    echo "📍 Введите IP-адрес сервера:"
    echo "   - Для доступа со всех интерфейсов: 0.0.0.0"
    echo "   - Для локального доступа: 127.0.0.1"
    echo "   - IP вашего сервера, например: 192.168.1.100"
    echo ""
    read -p "IP-адрес: " USER_IP

    # Validate IP format (basic check)
    if [[ ! $USER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Ошибка: Неверный формат IP-адреса"
        exit 1
    fi

    SERVER_IP="$USER_IP"

    echo ""
    echo "🔌 Введите порт для сервера (по умолчанию 8000):"
    read -p "Порт: " USER_PORT

    # Use default if empty
    if [ -z "$USER_PORT" ]; then
        USER_PORT=8000
    fi

    # Validate port (basic check)
    if ! [[ $USER_PORT =~ ^[0-9]+$ ]] || [ "$USER_PORT" -lt 1024 ] || [ "$USER_PORT" -gt 65535 ]; then
        echo "❌ Ошибка: Порт должен быть числом от 1024 до 65535"
        exit 1
    fi

    SERVER_PORT="$USER_PORT"
    save_config "$SERVER_IP" "$SERVER_PORT"

    echo ""
    echo "✓ Настройки сохранены: $SERVER_IP:$SERVER_PORT"
    echo ""
else
    SERVER_IP="$SAVED_IP"
    SERVER_PORT="$SAVED_PORT"
fi

# Check if port is in use
if command -v lsof &> /dev/null; then
    if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "❌ Ошибка: Порт $SERVER_PORT уже занят"
        echo ""
        echo "Варианты:"
        echo "  1. Остановить приложение, использующее этот порт"
        echo "  2. Изменить SERVER_PORT в файле .env"
        echo "  3. При запуске указать другой порт: SERVER_PORT=8001 bash run.sh"
        echo ""
        read -p "Введите другой порт или нажмите Enter для выхода: " NEW_PORT

        if [ -z "$NEW_PORT" ]; then
            exit 1
        fi

        # Validate port
        if ! [[ $NEW_PORT =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
            echo "❌ Ошибка: Неверный порт"
            exit 1
        fi

        SERVER_PORT="$NEW_PORT"
        save_config "$SERVER_IP" "$SERVER_PORT"
        echo "✓ Порт изменён на $SERVER_PORT"
        echo ""
    fi
fi

DOCROOT="$SCRIPT_DIR/web"

# Check PHP
if ! command -v php &> /dev/null; then
    echo "❌ Error: PHP is not installed"
    echo "Install PHP: sudo apt-get install php-cli"
    exit 1
fi

# Check GD extension
if ! php -m | grep -q gd; then
    echo "⚠️  Warning: GD extension not found"
    echo "Install: sudo apt-get install php-gd"
    echo ""
fi

# Print header
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│   Image Processor Server                    │"
echo "│   Standalone Image Optimizer & Resizer      │"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "📍 Server Information:"
echo "   Address: http://localhost:$SERVER_PORT"
echo "   Server:  $SERVER_IP:$SERVER_PORT"
echo "   Root:    $DOCROOT"
echo ""
echo "🎯 Features:"
echo "   ✓ Drag-and-drop image upload"
echo "   ✓ Multiple format support (JPG, PNG, GIF, WebP)"
echo "   ✓ Quality slider (0-100)"
echo "   ✓ 8 thumbnail sizes (300px - 2560px)"
echo ""
echo "🛑 Controls:"
echo "   Press Ctrl+C to stop the server"
echo ""
echo "📝 Default Settings:"
echo "   Quality: 85 (balanced)"
echo "   Default Sizes: 300px, 600px, 1200px"
echo ""

# Start server
exec php -S "$SERVER_IP:$SERVER_PORT" -t "$DOCROOT" -r router.php
