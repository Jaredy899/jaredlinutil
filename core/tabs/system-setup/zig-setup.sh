#!/bin/sh -e

. ../common-script.sh

ZIG_VERSION="0.13.0"
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib"

installZig() {
    # Check if zig is installed
    if command -v zig >/dev/null 2>&1; then
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Zig...${RC}"

    # First try package manager installation
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed zig=0.13.0
            ;;
        dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y zig
            ;;
        zypper)
            if grep -q "Tumbleweed" /etc/os-release; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y zig
            else
                PACKAGE_MANAGER_FAILED=true
            fi
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add zig
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -S zig
            ;;
        *)
            PACKAGE_MANAGER_FAILED=true
            ;;
    esac

    # Fall back to manual installation if package manager failed
    if [ "${PACKAGE_MANAGER_FAILED:-}" = "true" ]; then
        printf "%b\n" "${YELLOW}No package manager installation available, installing Zig ${ZIG_VERSION} manually...${RC}"

        # Determine architecture using uname
        ARCH="$(uname -m)"
        if [ "$ARCH" = "aarch64" ]; then
            ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-aarch64-${ZIG_VERSION}.tar.xz"
            ZIG_DIR="zig-linux-aarch64-${ZIG_VERSION}"
        else
            ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
            ZIG_DIR="zig-linux-x86_64-${ZIG_VERSION}"
        fi

        # Download and extract Zig
        curl -LO "${ZIG_URL}"
        tar -xf "${ZIG_DIR}.tar.xz"

        # Apply patch for aarch64 on Raspberry Pi
        if [ "$ARCH" = "aarch64" ] && grep -q "Raspberry Pi" /proc/cpuinfo; then
            MEM_ZIG_PATH="${ZIG_DIR}/lib/std/mem.zig"
            if [ -f "$MEM_ZIG_PATH" ]; then
                sed -i 's/4 \* 1024/16 \* 1024/' "$MEM_ZIG_PATH"
            fi
        fi

        # Install Zig with distribution-specific paths
        "$ESCALATION_TOOL" mkdir -p "$LIB_DIR"
        "$ESCALATION_TOOL" mv "${ZIG_DIR}" "$LIB_DIR/"
        "$ESCALATION_TOOL" ln -sf "$LIB_DIR/${ZIG_DIR}/zig" "$INSTALL_DIR/zig"
        rm "${ZIG_DIR}.tar.xz"
    fi
}

checkEnv
checkEscalationTool
installZig