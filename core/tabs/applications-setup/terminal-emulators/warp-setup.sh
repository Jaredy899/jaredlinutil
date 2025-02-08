#!/bin/sh -e

. ../../common-script.sh


installWarp() {
    local invalid_package=false
    local appimage_path=""

    if ! command_exists warp-terminal; then
        printf "%b\n" "${YELLOW}Installing Warp...${RC}"

        case "$PACKAGER" in
            pacman)
                TEMP_FILE="warp-latest.pkg"
                curl -o "$TEMP_FILE" -JLO https://app.warp.dev/download?package=pacman
                if [[ "$TEMP_FILE" != *.pkg.tar.zst ]]; then
                    mv "$TEMP_FILE" "$TEMP_FILE.pkg.tar.zst"
                fi
                sudo pacman -U "$TEMP_FILE.pkg.tar.zst" || invalid_package=true
                ;;
            apt-get|nala)
                TEMP_DEB_FILE="warp-latest.deb"
                curl -o "$TEMP_DEB_FILE" -JLO https://app.warp.dev/download?package=deb
                if file "$TEMP_DEB_FILE" | grep -q 'Debian binary package'; then
                    "$ESCALATION_TOOL" dpkg -i "$TEMP_DEB_FILE" || "$ESCALATION_TOOL" "$PACKAGER" install -f
                else
                    invalid_package=true
                fi
                ;;
            dnf)
                TEMP_RPM_FILE="warp-latest.rpm"
                curl -o "$TEMP_RPM_FILE" -JLO https://app.warp.dev/download?package=rpm
                if file "$TEMP_RPM_FILE" | grep -q 'RPM'; then
                    "$ESCALATION_TOOL" rpm -i "$TEMP_RPM_FILE"
                else
                    invalid_package=true
                fi
                ;;
            zypper)
                TEMP_RPM_FILE="warp-latest.rpm"
                curl -o "$TEMP_RPM_FILE" -JLO https://app.warp.dev/download?package=rpm
                if file "$TEMP_RPM_FILE" | grep -q 'RPM'; then
                    "$ESCALATION_TOOL" rpm --import https://releases.warp.dev/linux/keys/warp.asc
                    "$ESCALATION_TOOL" zypper --no-gpg-checks install -y "$TEMP_RPM_FILE"
                else
                    invalid_package=true
                fi
                ;;
            *)
                printf "%b\n" "${YELLOW}Downloading Warp AppImage...${RC}"
                ARCH=$(uname -m)
                if [ "$ARCH" = "x86_64" ]; then
                    appimage_path="$HOME/.local/bin/Warp-x64.AppImage"
                    curl -L "https://app.warp.dev/download?package=appimage" -o "$appimage_path"
                    chmod +x "$appimage_path"
                elif [ "$ARCH" = "aarch64" ]; then
                    appimage_path="$HOME/.local/bin/Warp-ARM64.AppImage"
                    curl -L "https://app.warp.dev/download?package=appimage_arm64" -o "$appimage_path"
                    chmod +x "$appimage_path"
                else
                    printf "%b\n" "${RED}Unsupported architecture for AppImage.${RC}"
                    invalid_package=true
                fi

                # Add AppImage to system apps
                if [ -x "$appimage_path" ]; then
                    mkdir -p "$HOME/.local/share/applications"
                    mkdir -p "$HOME/.local/share/icons"
                    curl -o "$HOME/.local/share/icons/warp.png" "https://www.warp.dev/static/image/r/w=3840,q=90,format=auto/header_cf707f3073.png"
                    ICON_PATH="$HOME/.local/share/icons/warp.png"
                    cat <<EOF > "$HOME/.local/share/applications/warp.desktop"
[Desktop Entry]
Name=Warp
Exec=$appimage_path
Icon=$ICON_PATH
Type=Application
Categories=Utility;
EOF
                else
                    invalid_package=true
                fi
                ;;
        esac

        if [ "$invalid_package" = true ]; then
            printf "%b\n" "${RED}Downloaded file is not a valid package.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Warp is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installWarp