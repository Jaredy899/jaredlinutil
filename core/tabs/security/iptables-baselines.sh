#!/bin/sh -e

. ../common-script.sh

installPkg() {
    if ! command_exists iptables; then
        printf "%b\n" "${YELLOW}Installing iptables...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm iptables
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add iptables
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy iptables
                ;;
            slapt-get)
                "$ESCALATION_TOOL" "$PACKAGER" -y -i iptables
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y iptables
                ;;
        esac
    else
        printf "%b\n" "${GREEN}iptables is already installed${RC}"
    fi
}

configureIptables() {
    printf "%b\n" "${YELLOW}Using Recommended iptables Firewall Rules${RC}"

    # Clear existing rules
    printf "%b\n" "${YELLOW}Clearing existing iptables rules${RC}"
    "$ESCALATION_TOOL" iptables -F
    "$ESCALATION_TOOL" iptables -X
    "$ESCALATION_TOOL" iptables -t nat -F
    "$ESCALATION_TOOL" iptables -t nat -X
    "$ESCALATION_TOOL" iptables -t mangle -F
    "$ESCALATION_TOOL" iptables -t mangle -X
    "$ESCALATION_TOOL" iptables -P INPUT ACCEPT

    # Set default policies (deny all incoming, allow all outgoing, allow all loopback)
    printf "%b\n" "${YELLOW}Setting default policies${RC}"
    "$ESCALATION_TOOL" iptables -P INPUT DROP
    "$ESCALATION_TOOL" iptables -P FORWARD DROP
    "$ESCALATION_TOOL" iptables -P OUTPUT ACCEPT

    # Allow loopback
    printf "%b\n" "${YELLOW}Allowing loopback interface${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -i lo -j ACCEPT

    # Allow established and related connections
    printf "%b\n" "${YELLOW}Allowing established and related connections${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Rate limit SSH connections to prevent brute force attacks
    printf "%b\n" "${YELLOW}Limiting SSH connections to prevent brute force attacks${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Allow HTTP and HTTPS
    printf "%b\n" "${YELLOW}Allowing HTTP and HTTPS${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    # Block common attack vectors
    printf "%b\n" "${YELLOW}Blocking common attack vectors${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    "$ESCALATION_TOOL" iptables -A INPUT -f -j DROP

    # Allow ping but limit rate
    printf "%b\n" "${YELLOW}Allowing limited ping${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

    # Log and drop invalid packets
    printf "%b\n" "${YELLOW}Logging and dropping invalid packets${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -m conntrack --ctstate INVALID -j LOG --log-prefix "INVALID PACKET: "
    "$ESCALATION_TOOL" iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

    # Save rules
    printf "%b\n" "${YELLOW}Saving iptables rules${RC}"
    if command_exists iptables-save; then
        if [ -d /etc/iptables ]; then
            "$ESCALATION_TOOL" iptables-save > /etc/iptables/rules.v4
        elif [ -d /etc/sysconfig ]; then
            "$ESCALATION_TOOL" iptables-save > /etc/sysconfig/iptables
        else
            "$ESCALATION_TOOL" mkdir -p /etc/iptables
            "$ESCALATION_TOOL" iptables-save > /etc/iptables/rules.v4
        fi
    else
        printf "%b\n" "${RED}iptables-save not found. Rules not saved permanently.${RC}"
        printf "%b\n" "${YELLOW}You may need to configure your distro to load these rules on boot.${RC}"
    fi

    printf "%b\n" "${GREEN}Configured iptables with security baselines!${RC}"
}

checkEnv
checkEscalationTool
installPkg
configureIptables 