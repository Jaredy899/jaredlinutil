#!/bin/sh -e

. ../common-script.sh

installRust() {
    if ! command -v rustc >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Rust via rustup...${RC}"
        
        # Install rustup using the official installer with -y flag to accept all prompts
        # and sending an empty input to handle any additional confirmation prompts
        printf "\n" | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        
        # Source the cargo environment to make rust commands available in current shell
        . "$HOME/.cargo/env"
        
        # Verify installation
        if command -v rustc >/dev/null 2>&1 || [ -f "$HOME/.cargo/bin/rustc" ]; then
            printf "%b\n" "${GREEN}Rust installed successfully.${RC}"
            printf "%b\n" "${CYAN}Rust environment sourced for current session.${RC}"
        else
            printf "%b\n" "${RED}Rust installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Rust is already installed.${RC}"
    fi
}

checkEnv
installRust 