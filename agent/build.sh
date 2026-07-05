#!/usr/bin/env bash
# Packages main.py + dependencies into a zip that matches the layout AgentCore
# Runtime expects (entry_point main.py at the zip root). Bedrock AgentCore
# Runtime executes on ARM64, so dependencies are pulled as manylinux aarch64
# wheels regardless of the host architecture running this script.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$DIR/.build/pkg"
ZIP_PATH="$DIR/.build/agent-runtime.zip"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR"

pip install -r "$DIR/requirements.txt" \
  --platform manylinux2014_aarch64 \
  --python-version 3.13 \
  --implementation cp \
  --only-binary=:all: \
  --target "$BUILD_DIR"

cp "$DIR/main.py" "$BUILD_DIR/main.py"

(cd "$BUILD_DIR" && zip -qr "$ZIP_PATH" .)

echo "Built $ZIP_PATH"
