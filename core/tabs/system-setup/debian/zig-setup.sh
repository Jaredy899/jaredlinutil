#!/bin/bash
. ../../common-script.sh

installZig() {
    ZIG_VERSION="${1:-0.13.0}"

    # Determine architecture using uname
    ARCH="$(uname -m)"
    if [ "$ARCH" = "aarch64" ]; then
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-aarch64-${ZIG_VERSION}.tar.xz"
        ZIG_DIR="zig-linux-aarch64-${ZIG_VERSION}"
    else
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
        ZIG_DIR="zig-linux-x86_64-${ZIG_VERSION}"
    fi

    # Define installation directories (similar to the ghostty setup script)
    INSTALL_DIR="/usr/local/bin"
    LIB_DIR="/usr/local/lib"

    echo "Downloading Zig ${ZIG_VERSION} for architecture: $ARCH"
    curl -LO "${ZIG_URL}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download Zig from ${ZIG_URL}"
        exit 1
    fi

    echo "Extracting ${ZIG_DIR}.tar.xz..."
    tar -xf "${ZIG_DIR}.tar.xz"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to extract ${ZIG_DIR}.tar.xz"
        exit 1
    fi

    # Apply patch for Raspberry Pi on aarch64 if applicable
    if [ "$ARCH" = "aarch64" ] && grep -q "Raspberry Pi" /proc/cpuinfo; then
        MEM_ZIG_PATH="${ZIG_DIR}/lib/std/mem.zig"
        if [ -f "$MEM_ZIG_PATH" ]; then
            echo "Patching mem.zig for Raspberry Pi..."
            sed -i 's/4 \* 1024/16 \* 1024/' "$MEM_ZIG_PATH"
        fi
    fi

    echo "Installing Zig..."
    "$ESCALATION_TOOL" mkdir -p "$LIB_DIR"
    "$ESCALATION_TOOL" mv "${ZIG_DIR}" "$LIB_DIR/"
    "$ESCALATION_TOOL" ln -sf "$LIB_DIR/${ZIG_DIR}/zig" "$INSTALL_DIR/zig"

    # Cleanup the downloaded tarball
    rm "${ZIG_DIR}.tar.xz"

    echo "Zig ${ZIG_VERSION} installed successfully."
}

checkEnv
checkEscalationTool
installZig