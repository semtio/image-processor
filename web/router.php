<?php

/**
 * Router for Image Processor
 * Routes API requests to appropriate handlers
 */

// Get request path
$request_path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Routes handling
if (strpos($request_path, '/api/') !== false) {
    // API requests
    require __DIR__ . DIRECTORY_SEPARATOR . 'api.php';
} else {
    // Serve index.html for all other requests
    require __DIR__ . DIRECTORY_SEPARATOR . 'index.html';
}
