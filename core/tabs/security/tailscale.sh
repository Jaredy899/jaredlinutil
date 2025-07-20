#!/bin/sh -e

. ../common-script.sh

installTailscale() {
    if ! command_exists tailscale; then
        printf "%b\n" "${YELLOW}Installing Tailscale...${RC}"
        curl -fsSL https://tailscale.com/install.sh | sh
    else
        printf "%b\n" "${GREEN}Tailscale is already installed${RC}"
    fi
}

configureTailscale() {
    printf "%b\n" "${YELLOW}Configuring Tailscale...${RC}"
    "$ESCALATION_TOOL" tailscale up
}

checkEnv
checkEscalationTool
installTailscale
configureTailscale