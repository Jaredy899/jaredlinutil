#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Global variables
DM_EXISTS=0
DM="gdm"  # Default value for GNOME

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
    printf "%b\n" "${YELLOW}1. GDM (Recommended for GNOME) ${RC}" 
    printf "%b\n" "${YELLOW}2. LightDM ${RC}" 
    printf "%b\n" "${YELLOW}3. SDDM ${RC}" 
    printf "%b\n" "${YELLOW}4. None (Start GNOME manually) ${RC}" 
    printf "%b" "${YELLOW}Please select one (1-4): ${RC}"
    read -r choice
    
    case "$choice" in
        1)
            DM="gdm"
            ;;
        2)
            DM="lightdm"
            ;;
        3)
            DM="sddm"
            ;;
        4)
            DM="none"
            ;;
        *)
            printf "%b\n" "${RED}Invalid selection! Defaulting to GDM.${RC}"
            DM="gdm"
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
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm "$DM"
                if [ "$DM" = "lightdm" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm lightdm-gtk-greeter
                fi
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y "$DM"
                ;;
        esac
        enableService "$DM"
    fi
}

installGnome() {
    printf "%b\n" "${CYAN}Installing GNOME Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y task-gnome-desktop
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm gnome gnome-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-gnome-gnome
            installDisplayManager
            ;;
        apk)
            echo "gnome" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y gnome
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    if [ "$DM" = "none" ]; then
        printf "%b\n" "${GREEN}GNOME Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To start GNOME, you can create a ~/.xinitrc file with 'exec gnome-session' and run 'startx'.${RC}"
    else
        printf "%b\n" "${GREEN}GNOME Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please reboot your system and select GNOME from the session menu at the login screen.${RC}"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installGnome 