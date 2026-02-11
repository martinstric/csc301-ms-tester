#!/bin/bash
set -e

# Configuration
BINARY_NAME="a1-tester"
DIST_DIR="./dist"

# 1. Clean and prepare dist folder
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/mac" "$DIST_DIR/linux"

echo "🚀 Starting builds for $BINARY_NAME..."

# 2. Build for Mac (Native)
echo "🍏 Building for macOS..."
swift build -c release
cp ".build/release/$BINARY_NAME" "$DIST_DIR/mac/$BINARY_NAME"

# 3. Build for Linux (Docker)
# Use --platform linux/amd64 if you are on M1/M2/M3 but targeting Intel servers
echo "🐧 Building for Linux (Docker)..."
docker run --rm --platform linux/amd64 \
  -v "$PWD:/workspace" -w /workspace \
  swift:6.0-jammy \
  bash -c "swift package clean && \
           swift build -c release -Xswiftc -static-stdlib -Xswiftc -Osize && \
           strip -s .build/release/$BINARY_NAME"

# Find the Linux binary (it's often in a platform-specific subfolder)
LINUX_BIN_PATH=$(find .build -name "$BINARY_NAME" | grep "release" | grep "linux" | head -n 1)
cp "$LINUX_BIN_PATH" "$DIST_DIR/linux/$BINARY_NAME"

echo "✅ Done! Binaries are in $DIST_DIR"
ls -R "$DIST_DIR"
