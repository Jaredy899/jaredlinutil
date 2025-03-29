#!/bin/sh -e

. ../../common-script.sh

installRuby() {
    if ! command -v ruby >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Ruby...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed ruby
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ruby ruby-devel
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ruby-full
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ruby ruby-devel
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add ruby ruby-dev
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S ruby ruby-devel
                ;;
            *)
                printf "%b\n" "${RED}No package manager installation available for Ruby${RC}"
                return 1
                ;;
        esac
        
        # Verify installation
        if command -v ruby >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Ruby installed successfully. Version: $(ruby --version)${RC}"
        else
            printf "%b\n" "${RED}Ruby installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Ruby is already installed. Version: $(ruby --version)${RC}"
    fi

    # Install RVM for Ruby version management
    if ! command -v rvm >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing RVM for Ruby version management...${RC}"
        
        # Install RVM dependencies
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed gnupg curl
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnupg2 curl
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnupg2 curl
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gpg2 curl
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add gnupg curl
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S gnupg curl
                ;;
            *)
                printf "%b\n" "${YELLOW}Unable to install RVM dependencies via package manager${RC}"
                ;;
        esac
        
        # Install RVM
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB || true
        curl -sSL https://get.rvm.io | bash -s stable
        
        # Source RVM
        if [ -s "$HOME/.rvm/scripts/rvm" ]; then
            . "$HOME/.rvm/scripts/rvm"
            
            # Add RVM to shell profile
            {
                echo ''
                echo '# RVM'
                echo '[ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm"'
            } >> "$HOME/.bashrc"
            
            printf "%b\n" "${GREEN}RVM installed successfully.${RC}"
            printf "%b\n" "${CYAN}To start using RVM, restart your shell or run: source $HOME/.rvm/scripts/rvm${RC}"
        else
            printf "%b\n" "${RED}RVM installation failed.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}RVM is already installed.${RC}"
    fi
    
    # Install Bundler
    if ! command -v bundler >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Bundler...${RC}"
        gem install bundler
        
        if command -v bundler >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Bundler installed successfully. Version: $(bundler --version)${RC}"
        else
            printf "%b\n" "${RED}Bundler installation failed.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Bundler is already installed. Version: $(bundler --version)${RC}"
    fi
}

checkEnv
checkEscalationTool
installRuby 