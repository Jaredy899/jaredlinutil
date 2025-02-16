#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh


installPkg() {
    if ! command_exists ufw && ! command_exists firewalld; then
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
                        "$ESCALATION_TOOL" "$PACKAGER" add firewalld
                        ;;
                    xbps-install)
                        "$ESCALATION_TOOL" "$PACKAGER" -y firewalld
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

    printf "%b\n" "${YELLOW}Enabling and starting FirewallD${RC}"
    startAndEnableService firewalld

    printf "%b\n" "${YELLOW}Checking FirewallD state${RC}"
    "$ESCALATION_TOOL" firewall-cmd --state

    printf "%b\n" "${YELLOW}Setting default zone to drop (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --set-default-zone=drop

    printf "%b\n" "${YELLOW}Setting target to ACCEPT for outgoing traffic (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --zone=drop --set-target=ACCEPT

    printf "%b\n" "${YELLOW}Allowing SSH service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=ssh

    printf "%b\n" "${YELLOW}Allowing HTTP service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=http

    printf "%b\n" "${YELLOW}Allowing HTTPS service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=https

    printf "%b\n" "${YELLOW}Saving runtime configuration to permanent (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --runtime-to-permanent

    printf "%b\n" "${YELLOW}Reloading FirewallD configuration${RC}"
    "$ESCALATION_TOOL" firewall-cmd --reload

    printf "%b\n" "${GREEN}Enabled FirewallD with Baselines!${RC}"
}

applyFirewallConfiguration() {
    if command_exists ufw; then
        configureUFW
    elif command_exists firewalld; then
        configureFirewallD
    else
        printf "%b\n" "${RED}No supported firewall is installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPkg
applyFirewallConfiguration
