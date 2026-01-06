<?php

/**
 * Image Processor Configuration
 * This file stores server-specific settings
 */

return [
    // Server IP or hostname
    'server_ip' => getenv('SERVER_IP') ?? '0.0.0.0',

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
