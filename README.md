# Image Processor - MVP

Standalone image optimization and thumbnail generation application. Based on the Forge generator logic but completely independent and simplified for server deployment.

## Features

✨ **Core Features**
- 🖼️ Drag-and-drop multiple image uploads (unlimited quantity and size)
- 📦 Automatic thumbnail generation in multiple sizes
- 🎚️ Quality slider (0-100) for image compression control
- ✅ Checkbox selection for thumbnail sizes (300px to 2560px)
- 📥 Easy download of processed thumbnails
- 🚀 Built-in web server (no external Apache required)
- 🔧 Automatic server installation with all dependencies

## Supported Formats

- JPG / JPEG
- PNG
- GIF
- WebP

## Thumbnail Sizes

Standard responsive image sizes:
- **Mobile**: 300px, 400px, 600px
- **Tablet**: 768px, 1024px
- **Desktop**: 1200px, 1920px
- **High-DPI**: 2560px

## Installation

### Linux Server Setup

The application includes an automated installer script that handles all dependencies:

```bash
# 1. Navigate to the image-processor directory
cd /path/to/image-processor

# 2. Run setup with sudo (required for system-wide installation)
sudo bash setup.sh

# 3. Follow the interactive prompts:
#    - Enter server IP (0.0.0.0 for all interfaces)
#    - Enter port (default: 8000)
#    - Enter web directory path (default: /var/www/image-processor)
```

### What the Installer Does

The `setup.sh` script:
- ✓ Detects your Linux OS (Ubuntu, Debian, CentOS, RHEL, Fedora)
- ✓ Updates system packages
- ✓ Installs PHP with GD extension
- ✓ Installs Apache (optional, with mod_rewrite)
- ✓ Creates web directory with proper permissions
- ✓ Sets up systemd service for auto-start
- ✓ Creates convenient startup scripts
- ✓ Configures all necessary directories and permissions

### Manual Installation (Alternative)

If you prefer manual setup:

```bash
# 1. Install PHP and GD extension
sudo apt-get update
sudo apt-get install php-cli php-gd php-fileinfo

# 2. Create web directory
sudo mkdir -p /var/www/image-processor
sudo cp -r . /var/www/image-processor/

# 3. Set permissions
sudo chown -R www-data:www-data /var/www/image-processor/
sudo chmod -R 755 /var/www/image-processor/
sudo chmod -R 775 /var/www/image-processor/uploads
sudo chmod -R 775 /var/www/image-processor/output
```

## Running the Application

### Option 1: Using the Built-in PHP Server (Recommended for Small Deployments)

```bash
# Navigate to the installation directory
cd /var/www/image-processor

# Start the server
bash run.sh

# The app will be available at:
# http://localhost:8000
```

### Option 2: Using Systemd Service (Recommended for Production)

```bash
# Start the service
sudo systemctl start image-processor

# Enable auto-start on boot
sudo systemctl enable image-processor

# Check status
sudo systemctl status image-processor

# Stop the service
sudo systemctl stop image-processor

# View logs
sudo journalctl -u image-processor -f
```

### Option 3: Using Apache VirtualHost

If Apache was installed during setup:

```bash
# The VirtualHost is pre-configured
# Add to your /etc/hosts file:
echo "127.0.0.1 image-processor.local" | sudo tee -a /etc/hosts

# Access at:
# http://image-processor.local
```

## Web Interface Usage

### Step 1: Upload Images
- Click the upload area or drag-and-drop multiple images
- Supports JPG, PNG, GIF, WebP formats
- No file size or quantity limits

### Step 2: Configure Settings

**Quality Slider** (Left Panel)
- Range: 0 to 100
- 100 = Maximum quality, minimal compression
- 0 = Maximum compression, lowest quality
- Default: 85 (balanced)

**Thumbnail Sizes** (Right Panel)
- Check the sizes you want to generate
- Default selected: 300px, 600px, 1200px
- Multiple selections allowed

### Step 3: Process & Download
- Click "Process Images" button
- Thumbnails are generated on the server
- Download individual thumbnails directly

## Configuration

Edit `.env` file in the application directory:

```bash
SERVER_IP=0.0.0.0
SERVER_PORT=8000
WEB_DIR=/var/www/image-processor
```

Or edit `config/config.php` for advanced settings:

```php
return [
    'server_ip' => '0.0.0.0',
    'port' => 8000,
    'max_file_size' => 1000 * 1024 * 1024, // 1000 MB
    'default_quality' => 85,
    'thumbnail_sizes' => [300, 400, 600, 768, 1024, 1200, 1920, 2560],
];
```

## API Reference

### GET /api/config
Returns application configuration

```bash
curl http://localhost:8000/api/config
```

Response:
```json
{
    "success": true,
    "sizes": [300, 400, 600, 768, 1024, 1200, 1920, 2560],
    "port": 8000,
    "server_ip": "0.0.0.0"
}
```

### POST /api/upload
Upload and process image with thumbnails

```bash
curl -F "image=@photo.jpg" \
     -F "quality=85" \
     -F "sizes=[300,600,1200]" \
     http://localhost:8000/api/upload
```

Response:
```json
{
    "success": true,
    "file": "img_abc123.jpg",
    "original_size": 2048576,
    "thumbnails": [
        {
            "size": 300,
            "filename": "img_abc123-300w.jpg",
            "path": "/var/www/image-processor/output/img_abc123-300w.jpg",
            "file_size": 45234
        },
        ...
    ],
    "errors": []
}
```

### GET /api/download
Download processed thumbnail

```bash
curl -O http://localhost:8000/api/download?file=img_abc123-300w.jpg
```

## Directory Structure

```
image-processor/
├── setup.sh                 # Linux installation script
├── run.sh                   # Server startup script
├── app/
│   └── ImageProcessor.php   # Core image processing class
├── web/
│   ├── index.html          # Web interface (frontend)
│   ├── api.php             # REST API handler
│   ├── router.php          # Route dispatcher
│   └── .htaccess           # Apache configuration
├── config/
│   └── config.php          # Configuration file
├── uploads/                # Temporary upload directory
├── output/                 # Processed thumbnails directory
└── README.md               # This file
```

## Performance Notes

- Images are not stored, only thumbnails are kept
- Original uploads are deleted after processing
- Old files (>24h) are auto-cleaned
- Supports concurrent uploads
- Processing is optimized for large batches

## Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use a different port
SERVER_PORT=8001 php -S 0.0.0.0:8001 -t web -r router.php
```

### Permission Denied

```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/image-processor
sudo chmod -R 755 /var/www/image-processor
sudo chmod -R 775 /var/www/image-processor/uploads
sudo chmod -R 775 /var/www/image-processor/output
```

### GD Extension Not Found

```bash
# Check if GD is installed
php -m | grep gd

# Install GD (Ubuntu/Debian)
sudo apt-get install php-gd

# Restart PHP
sudo systemctl restart php-fpm
```

### File Upload Limits

Edit `/etc/php/*/cli/php.ini` or use .htaccess:

```
upload_max_filesize = 1000M
post_max_size = 1000M
max_file_uploads = 100
```

## Security Considerations

- All uploads are validated by MIME type
- Uploaded originals are deleted after processing
- Output files are accessible only via API
- API endpoints have basic error handling
- Consider adding authentication for production use
- Use HTTPS in production environments

## Based On

This application is inspired by the Forge generator's image processing logic but designed as a standalone, simplified MVP for server deployment.

## License

This standalone application is provided as-is for image optimization and thumbnail generation.

## Support

For issues or questions:
1. Check the installation log: `install.log`
2. Review systemd logs: `sudo journalctl -u image-processor -f`
3. Verify PHP GD extension: `php -m | grep gd`
4. Test API endpoint: `curl http://localhost:8000/api/config`
