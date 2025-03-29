#!/bin/sh -e

. ../../common-script.sh

installNode() {
    if ! command -v node >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Node.js...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed nodejs npm
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y nodejs npm
                ;;
            apt-get|nala)
                # Add NodeSource repository for latest Node.js
                "$ESCALATION_TOOL" curl -fsSL https://deb.nodesource.com/setup_lts.x | "$ESCALATION_TOOL" bash -
                "$ESCALATION_TOOL" "$PACKAGER" install -y nodejs
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y nodejs npm
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add nodejs npm
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S nodejs npm
                ;;
            *)
                # Fall back to NVM installation
                PACKAGE_MANAGER_FAILED=true
                ;;
        esac

        # Fall back to NVM installation if package manager failed
        if [ "${PACKAGE_MANAGER_FAILED:-}" = "true" ]; then
            printf "%b\n" "${YELLOW}No package manager installation available, installing Node.js via NVM...${RC}"
            
            # Install NVM
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            
            # Load NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            # Install LTS version of Node.js
            nvm install --lts
            nvm use --lts
            nvm alias default node
        fi
        
        # Verify installation
        if command -v node >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Node.js installed successfully. Version: $(node -v)${RC}"
            if command -v npm >/dev/null 2>&1; then
                printf "%b\n" "${GREEN}NPM installed successfully. Version: $(npm -v)${RC}"
            fi
        else
            printf "%b\n" "${RED}Node.js installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Node.js is already installed. Version: $(node -v)${RC}"
        if command -v npm >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}NPM is already installed. Version: $(npm -v)${RC}"
        fi
    fi
}

checkEnv
checkEscalationTool
installNode 