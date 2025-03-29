#!/bin/sh -e

. ../../common-script.sh

installKotlin() {
    if ! command -v kotlin >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Kotlin...${RC}"

        # Check if Java is installed first, as Kotlin requires it
        if ! command -v java >/dev/null 2>&1; then
            printf "%b\n" "${YELLOW}Kotlin requires Java. Installing Java first...${RC}"
            if [ -f "$(dirname "$0")/java-setup.sh" ]; then
                sh "$(dirname "$0")/java-setup.sh"
            else
                printf "%b\n" "${RED}Java installation script not found. Please install Java first.${RC}"
                return 1
            fi
        fi

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed kotlin
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y kotlin
                ;;
            apt-get|nala)
                if ! apt-cache search kotlin | grep -q "^kotlin "; then
                    printf "%b\n" "${YELLOW}Kotlin not available in repositories, installing via SDKMAN...${RC}"
                    PACKAGE_MANAGER_FAILED=true
                else
                    "$ESCALATION_TOOL" "$PACKAGER" install -y kotlin
                fi
                ;;
            *)
                # Most package managers don't have Kotlin packages
                PACKAGE_MANAGER_FAILED=true
                ;;
        esac

        # Fall back to SDKMAN installation if package manager failed
        if [ "${PACKAGE_MANAGER_FAILED:-}" = "true" ]; then
            printf "%b\n" "${YELLOW}Installing Kotlin via SDKMAN...${RC}"
            
            # Install SDKMAN if not already installed
            if ! command -v sdk >/dev/null 2>&1; then
                printf "%b\n" "${YELLOW}Installing SDKMAN...${RC}"
                curl -s "https://get.sdkman.io" | bash
                
                # Source SDKMAN
                export SDKMAN_DIR="$HOME/.sdkman"
                [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
            else
                printf "%b\n" "${GREEN}SDKMAN is already installed.${RC}"
                # Source SDKMAN
                export SDKMAN_DIR="$HOME/.sdkman"
                [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
            fi
            
            # Install Kotlin using SDKMAN
            sdk install kotlin
        fi
        
        # Verify installation
        if command -v kotlin >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Kotlin installed successfully. Version: $(kotlin -version 2>&1)${RC}"
        else
            # Try to find it in SDKMAN
            if [ -d "$HOME/.sdkman/candidates/kotlin/current/bin" ]; then
                printf "%b\n" "${GREEN}Kotlin installed via SDKMAN.${RC}"
                printf "%b\n" "${CYAN}To use Kotlin, run: export PATH=\$PATH:\$HOME/.sdkman/candidates/kotlin/current/bin${RC}"
                printf "%b\n" "${CYAN}Or restart your shell session.${RC}"
            else
                printf "%b\n" "${RED}Kotlin installation failed.${RC}"
                return 1
            fi
        fi
    else
        printf "%b\n" "${GREEN}Kotlin is already installed. Version: $(kotlin -version 2>&1)${RC}"
    fi
}

checkEnv
checkEscalationTool
installKotlin 