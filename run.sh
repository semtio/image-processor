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

# Function to save IP to .env
save_ip() {
    local ip="$1"
    if [ -f "$ENV_FILE" ]; then
        # Update existing .env
        sed -i.bak "s/^SERVER_IP=.*/SERVER_IP=$ip/" "$ENV_FILE"
    else
        # Create new .env
        echo "SERVER_IP=$ip" > "$ENV_FILE"
        echo "SERVER_PORT=8000" >> "$ENV_FILE"
    fi
}

# Check if IP is already configured
SAVED_IP=$(get_saved_ip)

if [ -z "$SAVED_IP" ] || [ "$SAVED_IP" = "0.0.0.0" ]; then
    echo ""
    echo "┌─────────────────────────────────────────────┐"
    echo "│   Image Processor - First Time Setup       │"
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
    save_ip "$SERVER_IP"

    echo ""
    echo "✓ IP-адрес сохранён: $SERVER_IP"
    echo ""
else
    SERVER_IP="$SAVED_IP"
fi

# Set defaults
SERVER_PORT=${SERVER_PORT:-8000}
DOCROOT="$SCRIPT_DIR/web"

# Check if port is in use
if command -v lsof &> /dev/null; then
    if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "❌ Error: Port $SERVER_PORT is already in use"
        echo ""
        echo "Options:"
        echo "  1. Stop the application using that port"
        echo "  2. Change SERVER_PORT in .env file"
        echo "  3. Use a different port: SERVER_PORT=8001 bash run.sh"
        exit 1
    fi
fi

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
