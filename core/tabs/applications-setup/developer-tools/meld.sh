#!/bin/sh -e

. ../../common-script.sh

installMeld() {
    if ! command_exists org.gnome.meld && ! command_exists meld; then
        printf "%b\n" "${YELLOW}Installing Meld...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm meld
                ;;
            apt-get|nala|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y meld
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add meld
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy meld
                ;;
            slapt-get)
                "$ESCALATION_TOOL" "$PACKAGER" -y -i meld
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install -y flathub org.gnome.meld
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Meld is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installMeld
