#!/bin/sh -e

. ../common-script.sh

upgradeToEdge() {
    printf "%b\n" "${YELLOW}Backing up repositories file...${RC}"
    "$ESCALATION_TOOL" cp /etc/apk/repositories /etc/apk/repositories.backup

    printf "%b\n" "${YELLOW}Updating repositories to edge...${RC}"
    "$ESCALATION_TOOL" sh -c 'cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF'

    printf "%b\n" "${YELLOW}Updating package index...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" update

    printf "%b\n" "${YELLOW}Upgrading all packages...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" upgrade

    printf "%b\n" "${GREEN}Upgrade to Alpine edge completed!${RC}"
    printf "%b\n" "${YELLOW}Note: If you encounter any issues, you can restore your previous repositories file from /etc/apk/repositories.backup${RC}"
}

checkEnv
upgradeToEdge 