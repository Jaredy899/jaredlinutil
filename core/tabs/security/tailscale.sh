#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

installTailscale() {
    if ! command_exists tailscale; then
        printf "%b\n" "${YELLOW}Installing Tailscale...${RC}"
        case "$PACKAGER" in
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y tailscale
                startAndEnableService tailscaled
                printf "%b\n" "${GREEN}Tailscale installed successfully!${RC}"
                printf "%b\n" "${YELLOW}Please run 'sudo tailscale up' to complete the setup${RC}"
                return
                ;;
            *)
                curl -fsSL https://tailscale.com/install.sh | sh
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Tailscale is already installed${RC}"
    fi
}

configureTailscale() {
    if [ "$PACKAGER" = "eopkg" ]; then
        return
    fi
    printf "%b\n" "${YELLOW}Configuring Tailscale...${RC}"
    "$ESCALATION_TOOL" tailscale up
}

checkEnv
checkEscalationTool
installTailscale
configureTailscale