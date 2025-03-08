#!/bin/sh -e

. ../common-script.sh

installPodman() {
    if ! command_exists podman; then
        printf "%b\n" "${YELLOW}Installing Podman...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y podman
                ;;
            slapt-get)
                "$ESCALATION_TOOL" "$PACKAGER" -y -i podman
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Podman is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPodman
