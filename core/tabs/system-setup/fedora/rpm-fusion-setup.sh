#!/bin/sh -e

. ../../common-script.sh

# https://rpmfusion.org/Configuration

installRPMFusion() {
    case "$PACKAGER" in
        dnf)
            if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing RPM Fusion...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
                if "$PACKAGER" --version | grep -q "5."; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt --repo=fedora-cisco-openh264 enabled=1
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt --repo=rpmfusion-nonfree-updates enabled=1
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt --repo=rpmfusion-free-updates enabled=1
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled fedora-cisco-openh264
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-nonfree-updates
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-free-updates
                fi
                
                printf "%b\n" "${GREEN}RPM Fusion installed and enabled${RC}"
            else
                printf "%b\n" "${GREEN}RPM Fusion already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installRPMFusion