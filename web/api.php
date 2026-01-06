<?php

/**
 * REST API for image processing
 * Handles file uploads and thumbnail generation
 */

header('Content-Type: application/json; charset=utf-8');

// Error handler
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    error_log("[$errno] $errstr in $errfile:$errline");
});

// Get root directory
$root = dirname(dirname(__DIR__));

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Load configuration
$configFile = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'config.php';
$config = file_exists($configFile) ? require $configFile : [];

// Initialize directories
$uploadDir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'uploads';
$outputDir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'output';

// Load ImageProcessor class
require dirname(__DIR__) . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR . 'ImageProcessor.php';

$processor = new ImageProcessor($uploadDir, $outputDir);

// Route: GET /api/config
if ($_SERVER['REQUEST_METHOD'] === 'GET' && strpos($_SERVER['REQUEST_URI'], '/api/config') !== false) {
    echo json_encode([
        'success' => true,
        'sizes' => $processor->getAvailableSizes(),
        'port' => $config['port'] ?? 8000,
        'server_ip' => $config['server_ip'] ?? $_SERVER['HTTP_HOST'] ?? 'localhost:8000'
    ]);
    exit;
}

// Route: POST /api/upload
if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($_SERVER['REQUEST_URI'], '/api/upload') !== false) {
    handleUpload($processor, $uploadDir, $outputDir);
    exit;
}

// Route: POST /api/process
if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($_SERVER['REQUEST_URI'], '/api/process') !== false) {
    handleProcess($processor);
    exit;
}

// Route: GET /api/download
if ($_SERVER['REQUEST_METHOD'] === 'GET' && strpos($_SERVER['REQUEST_URI'], '/api/download') !== false) {
    handleDownload($outputDir);
    exit;
}

// Default 404
http_response_code(404);
echo json_encode(['error' => 'Endpoint not found']);
exit;

// --- Functions ---

function handleUpload($processor, $uploadDir, $outputDir) {
    if (!isset($_FILES['image'])) {
        http_response_code(400);
        echo json_encode(['error' => 'No image uploaded']);
        return;
    }

    $file = $_FILES['image'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['error' => 'Upload error: ' . getUploadErrorMessage($file['error'])]);
        return;
    }

    // Validate MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    $allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!in_array($mime, $allowedMimes)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid image format: ' . $mime]);
        return;
    }

    // Generate unique filename
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid('img_', true) . '.' . $ext;
    $filepath = $uploadDir . DIRECTORY_SEPARATOR . $filename;

    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save file']);
        return;
    }

    // Get quality from request
    $quality = isset($_POST['quality']) ? (int)$_POST['quality'] : 85;
    $processor->setQuality($quality);

    // Get requested sizes
    $sizes = isset($_POST['sizes']) ? json_decode($_POST['sizes'], true) : [];

    // Process image
    $result = $processor->processImage($filepath, $sizes);

    // Clean up uploaded file after processing (keep only thumbnails)
    @unlink($filepath);

    echo json_encode($result);
}

function handleProcess($processor) {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['quality']) || !isset($data['sizes'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing parameters']);
        return;
    }

    $processor->setQuality((int)$data['quality']);

    echo json_encode(['success' => true, 'sizes' => $data['sizes']]);
}

function handleDownload($outputDir) {
    if (!isset($_GET['file'])) {
        http_response_code(400);
        echo json_encode(['error' => 'No file specified']);
        return;
    }

    $filename = basename($_GET['file']); // Prevent path traversal
    $filepath = $outputDir . DIRECTORY_SEPARATOR . $filename;

    if (!file_exists($filepath) || !is_file($filepath)) {
        http_response_code(404);
        echo json_encode(['error' => 'File not found']);
        return;
    }

    // Stream file
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="' . basename($filepath) . '"');
    header('Content-Length: ' . filesize($filepath));
    readfile($filepath);
    exit;
}

function getUploadErrorMessage($code) {
    $messages = [
        UPLOAD_ERR_INI_SIZE => 'File exceeds PHP upload_max_filesize',
        UPLOAD_ERR_FORM_SIZE => 'File exceeds form MAX_FILE_SIZE',
        UPLOAD_ERR_PARTIAL => 'File upload incomplete',
        UPLOAD_ERR_NO_FILE => 'No file uploaded',
        UPLOAD_ERR_NO_TMP_DIR => 'No temporary directory',
        UPLOAD_ERR_CANT_WRITE => 'Cannot write to temporary directory',
        UPLOAD_ERR_EXTENSION => 'Upload stopped by extension'
    ];

    return $messages[$code] ?? 'Unknown error';
}
