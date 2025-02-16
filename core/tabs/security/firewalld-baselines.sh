#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

configureFirewallD() {
    printf "%b\n" "${YELLOW}Configuring FirewallD with recommended rules${RC}"

    printf "%b\n" "${YELLOW}Checking FirewallD state${RC}"
    if ! "$ESCALATION_TOOL" firewall-cmd --state >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Starting and enabling FirewallD${RC}"
        stopService firewalld
        startAndEnableService firewalld
        
        if ! "$ESCALATION_TOOL" firewall-cmd --state; then
            printf "%b\n" "${RED}FirewallD failed to start properly. Please check system logs.${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${YELLOW}Setting default zone to drop (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --set-default-zone=drop

    printf "%b\n" "${YELLOW}Allowing SSH service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=ssh

    printf "%b\n" "${YELLOW}Allowing HTTP service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=http

    printf "%b\n" "${YELLOW}Allowing HTTPS service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=https

    printf "%b\n" "${YELLOW}Reloading FirewallD configuration${RC}"
    "$ESCALATION_TOOL" firewall-cmd --reload

    printf "%b\n" "${GREEN}Enabled FirewallD with Baselines!${RC}"
}

checkEnv
checkEscalationTool
configureFirewallD