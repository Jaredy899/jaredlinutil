#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

installPkg() {
    if ! "$ESCALATION_TOOL" ufw status >/dev/null 2>&1 && ! "$ESCALATION_TOOL" firewall-cmd --state >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Neither UFW nor FirewallD is installed.${RC}"
        printf "%b\n" "${YELLOW}Please choose which firewall to install:${RC}"
        printf "%b\n" "${YELLOW}1) UFW${RC}"
        printf "%b\n" "${YELLOW}2) FirewallD${RC}"
        read -r choice

        case "$choice" in
            1)
                printf "%b\n" "${YELLOW}Installing UFW...${RC}"
                case "$PACKAGER" in
                    pacman)
                        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ufw
                        ;;
                    apk)
                        "$ESCALATION_TOOL" "$PACKAGER" add ufw
                        ;;
                    xbps-install)
                        "$ESCALATION_TOOL" "$PACKAGER" -y ufw
                        ;;
                    *)
                        "$ESCALATION_TOOL" "$PACKAGER" install -y ufw
                        ;;
                esac
                ;;
            2)
                printf "%b\n" "${YELLOW}Installing FirewallD...${RC}"
                case "$PACKAGER" in
                    pacman)
                        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm firewalld
                        ;;
                    apk)
                        printf "%b\n" "${YELLOW}Installing FirewallD and required dependencies...${RC}"
                        "$ESCALATION_TOOL" "$PACKAGER" add dbus firewalld
                        printf "%b\n" "${YELLOW}Enabling D-Bus service...${RC}"
                        startAndEnableService dbus
                        startAndEnableService firewalld
                        sleep 2
                        ;;
                    *)
                        "$ESCALATION_TOOL" "$PACKAGER" install -y firewalld
                        ;;
                esac
                ;;
            *)
                printf "%b\n" "${RED}Invalid choice. Please run the script again and choose either '1' for UFW or '2' for FirewallD.${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}UFW or FirewallD is already installed${RC}"
    fi
}

configureUFW() {
    printf "%b\n" "${YELLOW}Using Chris Titus Recommended Firewall Rules${RC}"

    printf "%b\n" "${YELLOW}Disabling UFW${RC}"
    "$ESCALATION_TOOL" ufw disable

    printf "%b\n" "${YELLOW}Limiting port 22/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw limit 22/tcp

    printf "%b\n" "${YELLOW}Allowing port 80/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw allow 80/tcp

    printf "%b\n" "${YELLOW}Allowing port 443/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw allow 443/tcp

    printf "%b\n" "${YELLOW}Denying Incoming Packets by Default(UFW)${RC}"
    "$ESCALATION_TOOL" ufw default deny incoming

    printf "%b\n" "${YELLOW}Allowing Outcoming Packets by Default(UFW)${RC}"
    "$ESCALATION_TOOL" ufw default allow outgoing

    "$ESCALATION_TOOL" ufw enable
    printf "%b\n" "${GREEN}Enabled Firewall with Baselines!${RC}"
}

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

applyFirewallConfiguration() {
    if "$ESCALATION_TOOL" ufw status >/dev/null 2>&1; then
        configureUFW
    elif "$ESCALATION_TOOL" firewall-cmd --state >/dev/null 2>&1; then
        configureFirewallD
    else
        printf "%b\n" "${RED}No supported firewall is installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPkg
applyFirewallConfiguration
