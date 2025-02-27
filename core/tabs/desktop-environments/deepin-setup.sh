#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Global variables
DM_EXISTS=0
DM="lightdm"  # Default value

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
    printf "%b\n" "${YELLOW}1. LightDM (Recommended for Deepin) ${RC}" 
    printf "%b\n" "${YELLOW}2. GDM ${RC}" 
    printf "%b\n" "${YELLOW}3. SDDM ${RC}" 
    printf "%b\n" "${YELLOW}4. None (Start Deepin manually) ${RC}" 
    printf "%b" "${YELLOW}Please select one (1-4): ${RC}"
    read -r choice
    
    case "$choice" in
        1)
            DM="lightdm"
            ;;
        2)
            DM="gdm"
            ;;
        3)
            DM="sddm"
            ;;
        4)
            DM="none"
            ;;
        *)
            printf "%b\n" "${RED}Invalid selection! Defaulting to LightDM.${RC}"
            DM="lightdm"
            ;;
    esac
    
    DM_EXISTS=1
}

# Function to install display manager if needed
installDisplayManager() {
    if [ "$DM_EXISTS" -eq 1 ] && [ "$DM" != "none" ]; then
        printf "%b\n" "${CYAN}Installing and enabling $DM display manager...${RC}"
        case "$PACKAGE_MANAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y "$DM"
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y "$DM"
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -S --noconfirm "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -S --noconfirm lightdm-gtk-greeter
                fi
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y "$DM"
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y "$DM"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" add "$DM"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -y "$DM"
                ;;
            slapt-get)
                "$ESCALATION_TOOL" "$PACKAGE_MANAGER" --install "$DM"
                ;;
        esac
        enableService "$DM"
    fi
}

installDeepin() {
    printf "%b\n" "${CYAN}Installing Deepin Desktop Environment...${RC}"
    
    case "$PACKAGE_MANAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y deepin-desktop-environment
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y deepin-desktop
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -S --noconfirm deepin deepin-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y deepin-desktop
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y deepin-desktop
            installDisplayManager
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" add deepin-desktop
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -y deepin deepin-desktop
            installDisplayManager
            ;;
        slapt-get)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" --update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" --install deepin-desktop
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGE_MANAGER${RC}"
            exit 1
            ;;
    esac
    
    if [ "$DM" = "none" ]; then
        printf "%b\n" "${GREEN}Deepin Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To start Deepin, you can create a ~/.xinitrc file with 'exec startdde' and run 'startx'.${RC}"
    else
        printf "%b\n" "${GREEN}Deepin Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please reboot your system and select Deepin from the session menu at the login screen.${RC}"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installDeepin 