#!/bin/sh -e

. ../../common-script.sh

installGhostty() {    
    case "$PACKAGER" in
        pacman)
            printf "%b\n" "-----------------------------------------------------"
            printf "%b\n" "Select the package to install:"
            printf "%b\n" "1. ${CYAN}ghostty${RC}      (stable release)"
            printf "%b\n" "2. ${CYAN}ghostty-git${RC}  (compiled from the latest commit)"
            printf "%b\n" "-----------------------------------------------------"
            printf "%b" "Enter your choice: "
            read -r choice
            case $choice in
                1) "$ESCALATION_TOOL" pacman -S --noconfirm ghostty ;;
                2) "$AUR_HELPER" -S --needed --noconfirm ghostty-git ;;
                *)
                    printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                    return 1
                    ;;
            esac
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy ghostty
            ;;
        zypper|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
            ;;
        *)
            printf "%b\n" "${RED}Binary installation not available for your distribution.${RC}"
            return 1
            ;;
    esac

    printf "%b\n" "${GREEN}Ghostty installed from binaries!${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
installGhostty
