#!/bin/bash

################################################################################
# Image Processor Setup Script
# Standalone image optimization and thumbnail generator
#
# Usage: bash setup.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
LOG_FILE="$APP_DIR/install.log"

# Initialize log file
echo "Installation started at $(date)" > "$LOG_FILE"

# Helper functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root or with sudo
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        echo "Run: sudo bash setup.sh"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        log_error "Unable to detect OS"
        exit 1
    fi

    log_info "Detected OS: $OS $VER"
}

# Update system packages
update_system() {
    log "Updating system packages..."

    case "$OS" in
        ubuntu|debian)
            apt-get update >> "$LOG_FILE" 2>&1
            apt-get upgrade -y >> "$LOG_FILE" 2>&1
            ;;
        centos|rhel|fedora)
            yum update -y >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_warning "Unknown OS, skipping system update"
            ;;
    esac

    log_success "System packages updated"
}

# Install PHP and extensions
install_php() {
    log "Checking PHP installation..."

    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -v | head -n 1)
        log_success "PHP already installed: $PHP_VERSION"
        return 0
    fi

    log "Installing PHP..."

    case "$OS" in
        ubuntu|debian)
            apt-get install -y php-cli php-gd php-fileinfo >> "$LOG_FILE" 2>&1
            ;;
        centos|rhel|fedora)
            yum install -y php php-gd php-common >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_error "Unsupported OS for PHP installation"
            return 1
            ;;
    esac

    log_success "PHP installed successfully"
}

# Install Apache (optional)
install_web_server() {
    log "Checking web server..."

    case "$OS" in
        ubuntu|debian)
            if ! command -v apache2ctl >/dev/null 2>&1; then
                log "Installing Apache2..."
                apt-get install -y apache2 apache2-utils libapache2-mod-php >> "$LOG_FILE" 2>&1
                a2enmod rewrite >> "$LOG_FILE" 2>&1
                a2enmod php* >> "$LOG_FILE" 2>&1
                systemctl restart apache2
                log_success "Apache2 installed"
            else
                log_success "Apache2 already installed"
            fi
            ;;
        centos|rhel|fedora)
            if ! command -v httpd >/dev/null 2>&1; then
                log "Installing Apache..."
                yum install -y httpd mod_php >> "$LOG_FILE" 2>&1
                systemctl restart httpd
                log_success "Apache installed"
            else
                log_success "Apache already installed"
            fi
            ;;
    esac
}

# Install GD extension for image processing
install_gd_extension() {
    log "Checking GD extension..."

    if php -m | grep -q gd; then
        log_success "GD extension already enabled"
        return 0
    fi

    log "Installing GD extension..."

    case "$OS" in
        ubuntu|debian)
            apt-get install -y php-gd >> "$LOG_FILE" 2>&1
            ;;
        centos|rhel|fedora)
            yum install -y php-gd >> "$LOG_FILE" 2>&1
            ;;
    esac

    # Restart PHP-FPM if it's running
    if systemctl is-active --quiet php-fpm; then
        systemctl restart php-fpm >> "$LOG_FILE" 2>&1
    fi

    log_success "GD extension installed"
}

# Get configuration from user
get_user_config() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Image Processor Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Get server IP
    read -p "Enter server IP address [0.0.0.0]: " SERVER_IP
    SERVER_IP=${SERVER_IP:-0.0.0.0}

    # Get port
    read -p "Enter server port [8000]: " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-8000}

    # Get web directory
    read -p "Enter web directory path [/var/www/image-processor]: " WEB_DIR
    WEB_DIR=${WEB_DIR:-/var/www/image-processor}

    log_info "Configuration Summary:"
    echo "  Server IP: $SERVER_IP"
    echo "  Port: $SERVER_PORT"
    echo "  Web Directory: $WEB_DIR"
    echo ""
}

# Create web directory and setup
setup_web_directory() {
    log "Setting up web directory..."

    # Create directory
    mkdir -p "$WEB_DIR" >> "$LOG_FILE" 2>&1

    # Copy application files
    cp -r "$APP_DIR"/* "$WEB_DIR/" >> "$LOG_FILE" 2>&1

    # Set permissions
    chown -R www-data:www-data "$WEB_DIR" >> "$LOG_FILE" 2>&1
    chmod -R 755 "$WEB_DIR" >> "$LOG_FILE" 2>&1
    chmod -R 775 "$WEB_DIR/uploads" >> "$LOG_FILE" 2>&1
    chmod -R 775 "$WEB_DIR/output" >> "$LOG_FILE" 2>&1

    log_success "Web directory setup completed: $WEB_DIR"
}

# Save configuration
save_config() {
    log "Saving configuration..."

    CONFIG_FILE="$WEB_DIR/config/config.php"

    # Update config file with user settings
    cat > "$CONFIG_FILE" << 'EOF'
<?php

/**
 * Image Processor Configuration
 * Generated during setup
 */

return [
    // Server IP or hostname
    'server_ip' => getenv('SERVER_IP') ?? 'localhost',

    // Server port
    'port' => (int)(getenv('SERVER_PORT') ?? 8000),

    // Maximum file upload size (bytes)
    'max_file_size' => 1000 * 1024 * 1024, // 1000 MB

    // Maximum number of concurrent uploads
    'max_concurrent_uploads' => 100,

    // Cleanup old files after (hours)
    'cleanup_hours' => 24,

    // Default quality for image compression (0-100)
    'default_quality' => 85,

    // Available thumbnail sizes
    'thumbnail_sizes' => [300, 400, 600, 768, 1024, 1200, 1920, 2560],

    // Supported image formats
    'supported_formats' => ['jpg', 'jpeg', 'png', 'gif', 'webp'],
];
EOF

    # Create environment file
    cat > "$WEB_DIR/.env" << EOF
SERVER_IP=$SERVER_IP
SERVER_PORT=$SERVER_PORT
WEB_DIR=$WEB_DIR
EOF

    chmod 600 "$WEB_DIR/.env" >> "$LOG_FILE" 2>&1

    log_success "Configuration saved"
}

# Setup Apache VirtualHost (optional)
setup_apache_vhost() {
    if ! command -v apache2ctl >/dev/null 2>&1; then
        return 0
    fi

    log "Setting up Apache VirtualHost..."

    VHOST_FILE="/etc/apache2/sites-available/image-processor.conf"
    VHOST_NAME="image-processor.local"

    if [ ! -f "$VHOST_FILE" ]; then
        cat > "$VHOST_FILE" << EOF
<VirtualHost *:80>
    ServerName $VHOST_NAME
    ServerAlias www.$VHOST_NAME

    DocumentRoot $WEB_DIR/web

    <Directory $WEB_DIR/web>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/image-processor-error.log
    CustomLog \${APACHE_LOG_DIR}/image-processor-access.log combined
</VirtualHost>
EOF

        a2ensite image-processor.conf >> "$LOG_FILE" 2>&1
        apache2ctl configtest >> "$LOG_FILE" 2>&1
        systemctl restart apache2 >> "$LOG_FILE" 2>&1

        log_success "Apache VirtualHost configured: $VHOST_NAME"
    fi
}

# Setup PHP built-in server (fallback)
setup_php_server() {
    log "Creating PHP server startup script..."

    SERVER_SCRIPT="$WEB_DIR/start-server.sh"

    cat > "$SERVER_SCRIPT" << 'EOF'
#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

SERVER_IP=${SERVER_IP:-0.0.0.0}
SERVER_PORT=${SERVER_PORT:-8000}
DOCROOT="$(dirname "$0")/web"

echo "Starting Image Processor..."
echo "Server: $SERVER_IP:$SERVER_PORT"
echo "Document Root: $DOCROOT"
echo "Open your browser: http://localhost:$SERVER_PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

php -S "$SERVER_IP:$SERVER_PORT" -t "$DOCROOT" -r router.php
EOF

    chmod +x "$SERVER_SCRIPT" >> "$LOG_FILE" 2>&1

    log_success "PHP server script created: $SERVER_SCRIPT"
}

# Create systemd service
setup_systemd_service() {
    log "Creating systemd service..."

    SERVICE_FILE="/etc/systemd/system/image-processor.service"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Image Processor - Image Optimization Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$WEB_DIR
ExecStart=/usr/bin/php -S 0.0.0.0:$SERVER_PORT -t $WEB_DIR/web -r router.php
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload >> "$LOG_FILE" 2>&1

    log_success "Systemd service created"
    log_info "To start service: sudo systemctl start image-processor"
    log_info "To enable auto-start: sudo systemctl enable image-processor"
}

# Create startup helper
create_startup_helper() {
    log "Creating startup helper..."

    HELPER_FILE="$WEB_DIR/run.sh"

    cat > "$HELPER_FILE" << 'EOF'
#!/bin/bash

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

SERVER_IP=${SERVER_IP:-0.0.0.0}
SERVER_PORT=${SERVER_PORT:-8000}

# Check if port is in use
if lsof -Pi :$SERVER_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "Error: Port $SERVER_PORT is already in use"
    exit 1
fi

echo "╔════════════════════════════════════════╗"
echo "║   Image Processor Server Started       ║"
echo "╠════════════════════════════════════════╣"
echo "║ Address: http://localhost:$SERVER_PORT   "
echo "║ Ctrl+C to stop                         ║"
echo "╚════════════════════════════════════════╝"
echo ""

exec php -S $SERVER_IP:$SERVER_PORT -t web -r router.php
EOF

    chmod +x "$HELPER_FILE" >> "$LOG_FILE" 2>&1

    log_success "Startup helper created: $HELPER_FILE"
}

# Print final instructions
print_instructions() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installation Completed Successfully!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Server IP: $SERVER_IP"
    echo "  Port: $SERVER_PORT"
    echo "  Web Directory: $WEB_DIR"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  1. Start the server:"
    echo "     cd $WEB_DIR"
    echo "     bash run.sh"
    echo ""
    echo "  2. Or use systemd service:"
    echo "     sudo systemctl start image-processor"
    echo ""
    echo "  3. Open in browser:"
    echo "     http://localhost:$SERVER_PORT"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  • Add to hosts file (optional):"
    echo "    echo '$SERVER_IP image-processor.local' | sudo tee -a /etc/hosts"
    echo ""
    echo "  • View logs:"
    echo "    tail -f $LOG_FILE"
    echo ""
    echo -e "${YELLOW}Note: Installation log saved to: $LOG_FILE${NC}"
    echo ""
}

# Main installation routine
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     Image Processor - Installation Script          ║"
    echo "║     Standalone Image Optimizer & Resizer           ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    log "Installation started"

    # Step 1: Check privileges
    check_privileges

    # Step 2: Detect OS
    detect_os

    # Step 3: Get user configuration
    get_user_config

    # Step 4: Update system
    log "Installing dependencies..."
    update_system

    # Step 5: Install PHP
    install_php

    # Step 6: Install GD extension
    install_gd_extension

    # Step 7: Install web server (Apache)
    install_web_server

    # Step 8: Setup web directory
    setup_web_directory

    # Step 9: Save configuration
    save_config

    # Step 10: Setup Apache VirtualHost
    setup_apache_vhost

    # Step 11: Create PHP server startup script
    setup_php_server

    # Step 12: Create startup helper
    create_startup_helper

    # Step 13: Setup systemd service
    setup_systemd_service

    # Print instructions
    print_instructions

    log_success "Installation completed successfully"
}

# Run main function
main "$@"
