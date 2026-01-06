<?php

/**
 * Image Processor - Main class for image optimization and thumbnail generation
 * Based on Forge generator logic, but standalone and simplified
 */

class ImageProcessor {

    // Thumbnail widths in pixels - standard responsive sizes
    private $widths = [300, 400, 600, 768, 1024, 1200, 1920, 2560];

    // Supported image formats
    private $formats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

    // Working directories
    private $uploadDir;
    private $outputDir;

    // Quality setting (0-100, where 0 is max compression, 100 is max quality)
    private $quality = 85;

    public function __construct(string $uploadDir, string $outputDir) {
        $this->uploadDir = $uploadDir;
        $this->outputDir = $outputDir;

        // Create directories if they don't exist
        if (!is_dir($this->uploadDir)) {
            mkdir($this->uploadDir, 0755, true);
        }
        if (!is_dir($this->outputDir)) {
            mkdir($this->outputDir, 0755, true);
        }
    }

    /**
     * Set quality for image compression
     * @param int $quality 0-100 (0 = max compression, 100 = max quality)
     */
    public function setQuality(int $quality): void {
        $this->quality = max(1, min(100, $quality));
    }

    /**
     * Get available thumbnail sizes
     */
    public function getAvailableSizes(): array {
        return $this->widths;
    }

    /**
     * Get image dimensions
     */
    private function getImageDims(string $path): ?array {
        $info = @getimagesize($path);
        if (!$info) {
            return null;
        }
        return [
            'w' => $info[0],
            'h' => $info[1],
            'type' => $info[2]
        ];
    }

    /**
     * Resize and compress image
     */
    private function resizeImage(
        string $src,
        string $dst,
        int $targetWidth,
        int $quality
    ): bool {
        $dims = $this->getImageDims($src);
        if (!$dims) {
            return false;
        }

        $origWidth = $dims['w'];
        $origHeight = $dims['h'];
        $type = $dims['type'];

        // Don't upscale: if target is larger than original, skip.
        // If target equals original width, allow re-encode for compression.
        if ($targetWidth > $origWidth) {
            return false;
        }

        // Calculate new height maintaining aspect ratio
        $newHeight = (int)round(($targetWidth / $origWidth) * $origHeight);

        // Load image based on type
        $image = null;
        switch ($type) {
            case IMAGETYPE_JPEG:
                $image = @imagecreatefromjpeg($src);
                break;
            case IMAGETYPE_PNG:
                $image = @imagecreatefrompng($src);
                break;
            case IMAGETYPE_GIF:
                $image = @imagecreatefromgif($src);
                break;
            case IMAGETYPE_WEBP:
                if (function_exists('imagecreatefromwebp')) {
                    $image = @imagecreatefromwebp($src);
                } else {
                    return false;
                }
                break;
            default:
                return false;
        }

        if (!$image) {
            return false;
        }

        // Create thumbnail
        $thumb = imagecreatetruecolor($targetWidth, $newHeight);
        if (!$thumb) {
            imagedestroy($image);
            return false;
        }

        // Handle transparency for PNG, GIF, WebP
        if ($type === IMAGETYPE_PNG || $type === IMAGETYPE_GIF || $type === IMAGETYPE_WEBP) {
            imagealphablending($thumb, false);
            imagesavealpha($thumb, true);
            $transparent = imagecolorallocatealpha($thumb, 255, 255, 255, 127);
            imagefilledrectangle($thumb, 0, 0, $targetWidth, $newHeight, $transparent);
        }

        // Resample image
        imagecopyresampled($thumb, $image, 0, 0, 0, 0, $targetWidth, $newHeight, $origWidth, $origHeight);

        // Save thumbnail
        $dstExt = strtolower(pathinfo($dst, PATHINFO_EXTENSION));
        $saved = false;

        switch ($dstExt) {
            case 'jpg':
            case 'jpeg':
                $saved = @imagejpeg($thumb, $dst, $quality);
                break;
            case 'png':
                // PNG quality 0-9 (inverse scale)
                $pngQuality = 9 - (int)round($quality / 11.11);
                $saved = @imagepng($thumb, $dst, $pngQuality);
                break;
            case 'gif':
                $saved = @imagegif($thumb, $dst);
                break;
            case 'webp':
                if (function_exists('imagewebp')) {
                    $saved = @imagewebp($thumb, $dst, $quality);
                } else {
                    $saved = false;
                }
                break;
        }

        imagedestroy($image);
        imagedestroy($thumb);

        return $saved;
    }

    /**
     * Generate thumbnail filename
     */
    private function getThumbnailName(string $filename, int $width): string {
        $pathInfo = pathinfo($filename);
        return $pathInfo['filename'] . '-' . $width . 'w.' . $pathInfo['extension'];
    }

    /**
     * Process uploaded image and generate thumbnails
     */
    public function processImage(
        string $uploadedFilePath,
        array $requestedSizes = []
    ): array {
        $results = [
            'success' => false,
            'file' => basename($uploadedFilePath),
            'original_size' => 0,
            'thumbnails' => [],
            'errors' => []
        ];

        // Verify file exists
        if (!is_file($uploadedFilePath)) {
            $results['errors'][] = 'File not found';
            return $results;
        }

        // Check extension
        $ext = strtolower(pathinfo($uploadedFilePath, PATHINFO_EXTENSION));
        if (!in_array($ext, $this->formats)) {
            $results['errors'][] = 'Unsupported format: ' . $ext;
            return $results;
        }

        $results['original_size'] = filesize($uploadedFilePath);

        // If no specific sizes requested, use all available
        $sizesToProcess = empty($requestedSizes) ? $this->widths : $requestedSizes;

        foreach ($sizesToProcess as $width) {
            if (!is_numeric($width) || $width < 100) {
                continue;
            }

            $width = (int)$width;
            $thumbName = $this->getThumbnailName(basename($uploadedFilePath), $width);
            $thumbPath = $this->outputDir . DIRECTORY_SEPARATOR . $thumbName;

            if ($this->resizeImage($uploadedFilePath, $thumbPath, $width, $this->quality)) {
                $results['thumbnails'][] = [
                    'size' => $width,
                    'filename' => $thumbName,
                    'path' => $thumbPath,
                    'file_size' => filesize($thumbPath)
                ];
            } else {
                $results['errors'][] = 'Failed to generate thumbnail for size: ' . $width;
            }
        }

        $results['success'] = count($results['thumbnails']) > 0;

        return $results;
    }

    /**
     * Clean up old files
     */
    public function cleanup(): void {
        // Remove old temp files older than 24 hours
        $cutoff = time() - (24 * 3600);

        if (!is_dir($this->outputDir)) {
            return;
        }

        $files = @scandir($this->outputDir);
        if (!$files) {
            return;
        }

        foreach ($files as $file) {
            if ($file === '.' || $file === '..') {
                continue;
            }

            $path = $this->outputDir . DIRECTORY_SEPARATOR . $file;
            if (is_file($path) && filemtime($path) < $cutoff) {
                @unlink($path);
            }
        }
    }
}
