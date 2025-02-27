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
    printf "%b\n" "${YELLOW}1. LightDM (Recommended for i3) ${RC}" 
    printf "%b\n" "${YELLOW}2. GDM ${RC}" 
    printf "%b\n" "${YELLOW}3. SDDM ${RC}" 
    printf "%b\n" "${YELLOW}4. None (Start i3 manually) ${RC}" 
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

installI3() {
    printf "%b\n" "${CYAN}Installing i3 Window Manager...${RC}"
    
    case "$PACKAGE_MANAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -S --noconfirm i3-wm i3status i3lock dmenu
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" install -y i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" add i3wm i3status i3lock dmenu
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" -y i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        slapt-get)
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" --update
            "$ESCALATION_TOOL" "$PACKAGE_MANAGER" --install i3 i3status i3lock dmenu
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGE_MANAGER${RC}"
            exit 1
            ;;
    esac

    setupI3Config
    
    if [ "$DM" = "none" ]; then
        printf "%b\n" "${GREEN}i3 Window Manager has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}To start i3, you can create a ~/.xinitrc file with 'exec i3' and run 'startx'.${RC}"
    else
        printf "%b\n" "${GREEN}i3 Window Manager has been installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please reboot your system and select i3 from the session menu at the login screen.${RC}"
    fi
}

setupI3Config() {
    # Create default i3 config if it doesn't exist
    if [ ! -d "$HOME/.config/i3" ]; then
        mkdir -p "$HOME/.config/i3"
        if command_exists i3-config-wizard; then
            printf "%b\n" "${YELLOW}Running i3-config-wizard to create a default config...${RC}"
            i3-config-wizard
        else
            printf "%b\n" "${YELLOW}Creating a basic i3 config file...${RC}"
            cat > "$HOME/.config/i3/config" << 'EOF'
# i3 config file (v4)
set $mod Mod4

# Font for window titles
font pango:monospace 8

# Use Mouse+$mod to drag floating windows
floating_modifier $mod

# Start a terminal
bindsym $mod+Return exec i3-sensible-terminal

# Kill focused window
bindsym $mod+Shift+q kill

# Start dmenu
bindsym $mod+d exec dmenu_run

# Change focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# Move focused window
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# Split in horizontal orientation
bindsym $mod+h split h

# Split in vertical orientation
bindsym $mod+v split v

# Enter fullscreen mode
bindsym $mod+f fullscreen toggle

# Change container layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# Change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# Focus the parent container
bindsym $mod+a focus parent

# Define names for workspaces
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# Switch to workspace
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# Reload the configuration file
bindsym $mod+Shift+c reload

# Restart i3 inplace
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

# Resize window
mode "resize" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt

        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Start i3bar
bar {
        status_command i3status
}
EOF
        fi
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installI3 