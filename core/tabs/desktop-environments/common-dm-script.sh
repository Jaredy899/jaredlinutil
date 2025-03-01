#!/bin/sh

. ../common-script.sh
. ../common-service-script.sh

# Common Display Manager functions
# This script should be sourced by desktop environment setup scripts

# Global variables (will be set by the sourcing script)
# DEFAULT_DM should be set before sourcing this script
# DM_OPTIONS should be set as an array of display managers in order of recommendation
# DE_NAME should be set to the name of the desktop environment

# Initialize variables if not set by sourcing script
: "${DEFAULT_DM:=lightdm}"
: "${DM_OPTIONS:="lightdm gdm sddm none"}"
: "${DM_LABELS:="LightDM|GDM|SDDM|None (Start manually)"}"
: "${DE_NAME:="Desktop Environment"}"

# Global variables used by this script
DM_EXISTS=0
DM="$DEFAULT_DM"  # Will be overridden if user selects a different one

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
    
    # No display manager found, ask if user wants to install one
    printf "%b\n" "${YELLOW}--------------------------${RC}" 
    printf "%b\n" "${YELLOW}No display manager detected${RC}" 
    printf "%b\n" "${YELLOW}A display manager provides a graphical login screen.${RC}"
    printf "%b\n" "${YELLOW}For ${CYAN}$DE_NAME${YELLOW}, the recommended display manager is ${CYAN}$DEFAULT_DM${YELLOW}.${RC}"
    printf "%b" "${YELLOW}Do you want to install a display manager? (Y/n): ${RC}"
    read -r install_dm
    
    case "$install_dm" in
        [Nn]*)
            printf "%b\n" "${YELLOW}Skipping display manager installation.${RC}"
            DM="none"
            DM_EXISTS=1
            return
            ;;
        *)
            # Continue to display manager selection
            ;;
    esac
    
    # No display manager found, prompt user to choose one
    printf "%b\n" "${YELLOW}--------------------------${RC}" 
    printf "%b\n" "${YELLOW}Pick your Display Manager ${RC}" 
    
    # Convert space-separated options and pipe-separated labels to arrays
    IFS=' ' read -r -a dm_options <<< "$DM_OPTIONS"
    IFS='|' read -r -a dm_labels <<< "$DM_LABELS"
    
    # Display options with the default one marked as recommended
    i=1
    for label in "${dm_labels[@]}"; do
        if [ "${dm_options[$((i-1))]}" = "$DEFAULT_DM" ]; then
            printf "%b\n" "${YELLOW}$i. $label (Recommended) ${RC}"
        else
            printf "%b\n" "${YELLOW}$i. $label ${RC}"
        fi
        i=$((i+1))
    done
    
    printf "%b" "${YELLOW}Please select one (1-${#dm_options[@]}): ${RC}"
    read -r choice
    
    # Validate choice
    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#dm_options[@]}" ] 2>/dev/null; then
        DM="${dm_options[$((choice-1))]}"
    else
        printf "%b\n" "${RED}Invalid selection! Defaulting to $DEFAULT_DM.${RC}"
        DM="$DEFAULT_DM"
    fi
    
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
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y "$DM"
                ;;
        esac
        enableService "$DM"
    fi
}

# Function to print post-installation message based on DM and DE
printDMMessage() {
    local DE_NAME="$1"
    local DE_START_CMD="$2"
    
    if [ "$DM" = "none" ]; then
        printf "%b\n" "${GREEN}$DE_NAME Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To start $DE_NAME, you can create a ~/.xinitrc file with 'exec $DE_START_CMD' and run 'startx'.${RC}"
    else
        printf "%b\n" "${GREEN}$DE_NAME Desktop Environment has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please reboot your system and select $DE_NAME from the session menu at the login screen.${RC}"
    fi
} 