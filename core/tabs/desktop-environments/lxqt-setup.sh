#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Global variables
DM_EXISTS=0
DM="sddm"  # Default value

checkDisplayManager() {
    printf "%b\n" "${CYAN}Checking for existing display managers...${RC}"
    
    # Check for common display managers
    for dm in gdm gdm3 lightdm sddm lxdm xdm slim; do
        # Check if the display manager is running
        if isServiceActive "$dm" 2>/dev/null; then
            printf "%b\n" "${YELLOW}Display manager $dm is already running.${RC}"
            DM_EXISTS=0
            return
        fi
        
        # Check if the display manager is enabled
        if isServiceEnabled "$dm" 2>/dev/null; then
            printf "%b\n" "${YELLOW}Display manager $dm is already enabled.${RC}"
            DM_EXISTS=0
            return
        fi
    done
    
    # No display manager found, prompt user to choose one
    printf "%b\n" "${YELLOW}--------------------------${RC}" 
    printf "%b\n" "${YELLOW}Pick your Display Manager ${RC}" 
    printf "%b\n" "${YELLOW}1. SDDM (Recommended for LXQt) ${RC}" 
    printf "%b\n" "${YELLOW}2. LightDM ${RC}" 
    printf "%b\n" "${YELLOW}3. GDM ${RC}" 
    printf "%b\n" "${YELLOW}4. None (Start LXQt manually) ${RC}" 
    printf "%b" "${YELLOW}Please select one (1-4): ${RC}"
    read -r choice
    
    case "$choice" in
        1)
            DM="sddm"
            ;;
        2)
            DM="lightdm"
            ;;
        3)
            DM="gdm"
            ;;
        4)
            DM="none"
            ;;
        *)
            printf "%b\n" "${RED}Invalid selection! Defaulting to SDDM.${RC}"
            DM="sddm"
            ;;
    esac
    
    DM_EXISTS=1
}

# Function to install display manager if needed
installDisplayManager() {
    if [ "$DM_EXISTS" -eq 1 ] && [ "$DM" != "none" ]; then
        printf "%b\n" "${CYAN}Installing and enabling $DM display manager...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm lightdm-gtk-greeter
                fi
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add "$DM"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y "$DM"
                ;;
            slapt-get)
                "$ESCALATION_TOOL" "$PACKAGER" --install "$DM"
                ;;
        esac
        enableService "$DM"
    fi
}

installLXQt() {
    printf "%b\n" "${CYAN}Installing LXQt Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y lxqt
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y "LXQt Desktop"
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm lxqt
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y -t pattern lxqt
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y lxqt
            installDisplayManager
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" add lxqt-desktop
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y lxqt
            installDisplayManager
            ;;
        slapt-get)
            "$ESCALATION_TOOL" "$PACKAGER" --update
            "$ESCALATION_TOOL" "$PACKAGER" --install lxqt
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGE_MANAGER${RC}"
            exit 1
            ;;
    esac
    
    if [ "$DM" = "none" ]; then
        printf "%b\n" "${GREEN}LXQt Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To start LXQt, you can create a ~/.xinitrc file with 'exec startlxqt' and run 'startx'.${RC}"
    else
        printf "%b\n" "${GREEN}LXQt Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please reboot your system and select LXQt from the session menu at the login screen.${RC}"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installLXQt 