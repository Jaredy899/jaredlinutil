#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

ensure_ssh_setup() {
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        printf "%b\n" "${GREEN}Created $SSH_DIR and set permissions to 700.${RC}"
    else
        printf "%b\n" "${YELLOW}$SSH_DIR already exists.${RC}"
    fi

    if [ ! -f "$AUTHORIZED_KEYS" ]; then
        touch "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        printf "%b\n" "${GREEN}Created $AUTHORIZED_KEYS and set permissions to 600.${RC}"
    else
        printf "%b\n" "${YELLOW}$AUTHORIZED_KEYS already exists.${RC}"
    fi
}

import_ssh_keys() {
    printf "%b" "${CYAN}Enter the GitHub username: ${RC}"
    read -r GITHUB_USER

    SSH_KEYS_URL="https://github.com/$GITHUB_USER.keys"
    KEYS=$(curl -s "$SSH_KEYS_URL")

    if [ -z "$KEYS" ]; then
        printf "%b\n" "${RED}No SSH keys found for GitHub user: $GITHUB_USER${RC}"
    else
        printf "%b\n" "${GREEN}SSH keys found for $GITHUB_USER:${RC}"
        printf "%s\n" "$KEYS"
        printf "%b" "${CYAN}Do you want to import these keys? [Y/n]: ${RC}"
        read -r CONFIRM

        case "$CONFIRM" in
            [Nn]*)
                printf "%b\n" "${YELLOW}SSH key import cancelled.${RC}"
                ;;
            *)
                printf "%s\n" "$KEYS" >> "$AUTHORIZED_KEYS"
                chmod 600 "$AUTHORIZED_KEYS"
                printf "%b\n" "${GREEN}SSH keys imported successfully!${RC}"
                ;;
        esac
    fi
}

add_manual_key() {
    printf "%b" "${CYAN}Enter the public key to add: ${RC}"
    read -r PUBLIC_KEY

    if grep -q "$PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
        printf "%b\n" "${YELLOW}Public key already exists in $AUTHORIZED_KEYS.${RC}"
    else
        printf "%s\n" "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        printf "%b\n" "${GREEN}Public key added to $AUTHORIZED_KEYS.${RC}"
    fi
}

show_ssh_menu() {
    show_menu_item 1 "${NC}" "Import from GitHub"
    show_menu_item 2 "${NC}" "Enter your own public key"
}

ssh_key_menu() {
    while true; do
        handle_menu_selection 2 "Select SSH key option:" show_ssh_menu
        CHOICE=$?
        case $CHOICE in
            1)
                import_ssh_keys
                break
                ;;
            2)
                add_manual_key
                break
                ;;
        esac
    done
}

checkEnv
ensure_ssh_setup
ssh_key_menu