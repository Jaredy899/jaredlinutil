#!/bin/sh -e

. ../../common-script.sh

installPython() {
    if ! command -v python3 >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Python...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed python python-pip
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3 python3-pip
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3 python3-pip python3-venv
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3 python3-pip
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add python3 py3-pip
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S python3 python3-pip
                ;;
            *)
                printf "%b\n" "${RED}No package manager installation available for Python${RC}"
                return 1
                ;;
        esac
        
        # Verify installation
        if command -v python3 >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Python installed successfully. Version: $(python3 --version)${RC}"
            if command -v pip3 >/dev/null 2>&1; then
                printf "%b\n" "${GREEN}pip installed successfully. Version: $(pip3 --version)${RC}"
            fi
        else
            printf "%b\n" "${RED}Python installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Python is already installed. Version: $(python3 --version)${RC}"
        if command -v pip3 >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}pip is already installed. Version: $(pip3 --version)${RC}"
        fi
    fi

    # Install pyenv for managing Python versions
    if ! command -v pyenv >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing pyenv for Python version management...${RC}"
        
        # Install pyenv dependencies
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed git base-devel openssl zlib xz
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y git gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y git build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y git gcc automake bzip2 libbz2-devel xz xz-devel openssl-devel ncurses-devel readline-devel zlib-devel tk-devel libffi-devel sqlite3-devel
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add git bash build-base libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S git gcc make bzip2 bzip2-devel readline-devel sqlite-devel openssl-devel xz xz-devel libffi-devel
                ;;
            *)
                printf "%b\n" "${YELLOW}Unable to install pyenv dependencies via package manager${RC}"
                ;;
        esac
        
        # Install pyenv
        curl https://pyenv.run | bash
        
        # Setup pyenv in shell
        {
            echo ''
            echo '# pyenv'
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'eval "$(pyenv init -)"'
        } >> "$HOME/.bashrc"
        
        printf "%b\n" "${GREEN}pyenv installed successfully.${RC}"
        printf "%b\n" "${CYAN}To start using pyenv, restart your shell or run: source $HOME/.bashrc${RC}"
    else
        printf "%b\n" "${GREEN}pyenv is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPython 