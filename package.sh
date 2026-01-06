#!/bin/bash

# Create a distribution package
# Usage: bash package.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="image-processor"
VERSION="1.0.0"
PACKAGE_NAME="${PROJECT_NAME}-${VERSION}.tar.gz"

echo "Packaging Image Processor..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$PROJECT_NAME"

mkdir -p "$PACKAGE_DIR"

# Copy files, excluding unwanted ones
rsync -av \
    --exclude=".git" \
    --exclude=".gitignore" \
    --exclude="node_modules" \
    --exclude="*.log" \
    --exclude=".env" \
    --exclude=".env.local" \
    --exclude="uploads/*" \
    --exclude="output/*" \
    --exclude=".DS_Store" \
    "$SCRIPT_DIR/" "$PACKAGE_DIR/" > /dev/null 2>&1

# Create tarball
cd "$TEMP_DIR"
tar -czf "$SCRIPT_DIR/$PACKAGE_NAME" "$PROJECT_NAME"

# Cleanup
rm -rf "$TEMP_DIR"

echo "✓ Package created: $PACKAGE_NAME"
echo "  Size: $(du -h "$SCRIPT_DIR/$PACKAGE_NAME" | cut -f1)"
echo ""
echo "Distribution ready!"
echo ""
echo "To use:"
echo "  1. Upload: scp $PACKAGE_NAME user@server:~/"
echo "  2. Extract: tar -xzf $PACKAGE_NAME"
echo "  3. Setup: cd $PROJECT_NAME && sudo bash setup.sh"
