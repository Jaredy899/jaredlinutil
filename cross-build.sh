#!/bin/bash

# Simple cross-compilation script for linutil with tree-sitter musl fixes
# Usage: ./cross-build.sh [target]
# Example: ./cross-build.sh aarch64-unknown-linux-musl

set -e

TARGET=${1:-"aarch64-unknown-linux-musl"}

case "$TARGET" in
    aarch64-unknown-linux-musl)
        echo "Building for aarch64-musl..."
        CC_aarch64_unknown_linux_musl="aarch64-linux-gnu-gcc" \
        CFLAGS_aarch64_unknown_linux_musl="-D_FORTIFY_SOURCE=0 -static" \
        cargo build --target aarch64-unknown-linux-musl --release
        ;;
    armv7-unknown-linux-musleabihf)
        echo "Building for armv7-musl..."
        CC_armv7_unknown_linux_musleabihf="arm-linux-gnueabihf-gcc" \
        CFLAGS_armv7_unknown_linux_musleabihf="-D_FORTIFY_SOURCE=0 -static" \
        cargo build --target armv7-unknown-linux-musleabihf --release
        ;;
    x86_64-unknown-linux-musl)
        echo "Building for x86_64-musl..."
        cargo build --target x86_64-unknown-linux-musl --release
        ;;
    *)
        echo "Usage: $0 [target]"
        echo "Supported targets:"
        echo "  - aarch64-unknown-linux-musl (default)"
        echo "  - armv7-unknown-linux-musleabihf"
        echo "  - x86_64-unknown-linux-musl"
        exit 1
        ;;
esac

echo "Build completed for $TARGET"
ls -la target/$TARGET/release/linutil 