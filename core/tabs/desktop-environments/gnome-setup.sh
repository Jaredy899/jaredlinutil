#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="GNOME"
DEFAULT_DM="gdm"
DM_OPTIONS="gdm lightdm sddm none"
DM_LABELS="GDM LightDM SDDM None (Start GNOME manually)"

# Source the common display manager script
. ./common-dm-script.sh

installGnome() {
    printf "%b\n" "${CYAN}Installing GNOME Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y task-gnome-desktop
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm gnome gnome-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-gnome-gnome
            installDisplayManager
            ;;
        apk)
            echo "gnome" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y gnome
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message
    printDMMessage "$DE_NAME" "gnome-session"
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installGnome 