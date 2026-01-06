<?php

/**
 * Router for Image Processor
 * Routes API requests to appropriate handlers
 */

// Get request path
$request_path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$script_dir = dirname($_SERVER['SCRIPT_NAME']);
$relative_path = substr($request_path, strlen($script_dir));

// Routes handling
if (strpos($relative_path, '/api/') === 0) {
    // API requests
    require dirname(__DIR__) . DIRECTORY_SEPARATOR . 'web' . DIRECTORY_SEPARATOR . 'api.php';
} else {
    // Serve index.html for all other requests
    require dirname(__DIR__) . DIRECTORY_SEPARATOR . 'web' . DIRECTORY_SEPARATOR . 'index.html';
}
