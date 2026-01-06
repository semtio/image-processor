#!/bin/bash

###############################################################################
# Image Processor Service Manager
# Helps manage the systemd service for Image Processor
#
# Usage: sudo bash manage-service.sh [start|stop|restart|status|enable|disable]
###############################################################################

SERVICE_NAME="image-processor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo"
    exit 1
fi

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Get command
COMMAND=${1:-status}

case "$COMMAND" in
    start)
        info "Starting Image Processor service..."
        systemctl start "$SERVICE_NAME"
        if [ $? -eq 0 ]; then
            success "Service started"
            sleep 1
            systemctl status "$SERVICE_NAME" --no-pager
        else
            error "Failed to start service"
            exit 1
        fi
        ;;

    stop)
        info "Stopping Image Processor service..."
        systemctl stop "$SERVICE_NAME"
        if [ $? -eq 0 ]; then
            success "Service stopped"
        else
            error "Failed to stop service"
            exit 1
        fi
        ;;

    restart)
        info "Restarting Image Processor service..."
        systemctl restart "$SERVICE_NAME"
        if [ $? -eq 0 ]; then
            success "Service restarted"
            sleep 1
            systemctl status "$SERVICE_NAME" --no-pager
        else
            error "Failed to restart service"
            exit 1
        fi
        ;;

    status)
        systemctl status "$SERVICE_NAME" --no-pager
        ;;

    enable)
        info "Enabling auto-start on boot..."
        systemctl enable "$SERVICE_NAME"
        if [ $? -eq 0 ]; then
            success "Service enabled for auto-start"
        else
            error "Failed to enable service"
            exit 1
        fi
        ;;

    disable)
        info "Disabling auto-start on boot..."
        systemctl disable "$SERVICE_NAME"
        if [ $? -eq 0 ]; then
            success "Service disabled"
        else
            error "Failed to disable service"
            exit 1
        fi
        ;;

    logs)
        info "Showing Image Processor logs (Ctrl+C to exit)..."
        journalctl -u "$SERVICE_NAME" -f
        ;;

    *)
        echo "Image Processor Service Manager"
        echo ""
        echo "Usage: sudo bash manage-service.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start       Start the service"
        echo "  stop        Stop the service"
        echo "  restart     Restart the service"
        echo "  status      Show service status"
        echo "  enable      Enable auto-start on boot"
        echo "  disable     Disable auto-start"
        echo "  logs        View service logs"
        echo ""
        exit 1
        ;;
esac
