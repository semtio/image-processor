<?php

/**
 * Router for Image Processor
 * Routes API requests to appropriate handlers
 */

// Check if this is an API request
if (strpos($_SERVER['REQUEST_URI'], '/api/') !== false) {
    // API requests
    require __DIR__ . DIRECTORY_SEPARATOR . 'api.php';
    exit;
}

// Serve static files
$path = __DIR__ . parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (is_file($path)) {
    return false; // Let PHP serve the file
}

// Default to index.html for all other requests
require __DIR__ . DIRECTORY_SEPARATOR . 'index.html';
