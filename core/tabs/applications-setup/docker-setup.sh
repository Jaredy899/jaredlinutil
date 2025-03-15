#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Function to prompt the user for installation choice
choose_installation() {
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}Docker${RC}"
    printf "%b\n" "2. ${YELLOW}Docker Compose${RC}"
    printf "%b\n" "3. ${YELLOW}Both${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE

    case "$CHOICE" in
        1) INSTALL_DOCKER=1; INSTALL_COMPOSE=0 ;;
        2) INSTALL_DOCKER=0; INSTALL_COMPOSE=1 ;;
        3) INSTALL_DOCKER=1; INSTALL_COMPOSE=1 ;;
        *) printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"; exit 1 ;;
    esac
}

install_docker() {
    printf "%b\n" "${YELLOW}Installing Docker...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            curl -fsSL https://get.docker.com | sh 
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core
            dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
            if [ "$dnf_version" -eq 4 ]; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            else
                "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin
            "$ESCALATION_TOOL" systemctl enable --now docker
            ;;
        zypper|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y docker
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm docker
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add docker
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy docker
            ;;
        slapt-get)
            "$ESCALATION_TOOL" "$PACKAGER" -y -i docker
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac

    startAndEnableService docker
}

install_docker_compose() {
    printf "%b\n" "${YELLOW}Installing Docker Compose...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y docker-compose-plugin
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core
            dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
            if [ "$dnf_version" -eq 4 ]; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            else
                "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" install -y docker-compose-plugin
            ;;
        zypper|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y docker-compose
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm docker-compose
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add docker-cli-compose
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy docker-compose
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" -y install docker-compose
            ;;
        slapt-get)
            "$ESCALATION_TOOL" "$PACKAGER" -y -i docker-compose
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

install_components() {
    choose_installation 

    if [ "$INSTALL_DOCKER" -eq 1 ]; then
        if ! command_exists docker; then
            install_docker
        else
            printf "%b\n" "${GREEN}Docker is already installed.${RC}"
        fi
    fi

    if [ "$INSTALL_COMPOSE" -eq 1 ]; then
        if ! command_exists docker-compose || ! command_exists docker compose version; then
            install_docker_compose
        else
            printf "%b\n" "${GREEN}Docker Compose is already installed.${RC}"
        fi
    fi
}

docker_permission() {
    printf "%b\n" "${YELLOW}Adding current user to the docker group...${RC}"
    "$ESCALATION_TOOL" usermod -aG docker "$USER"
    
    # Run a test command with sg to apply group changes immediately within the script
    if command -v sg >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Applying group changes for this session...${RC}"
        # sg docker -c "id" > /dev/null 2>&1
        sg docker -c "touch /dev/null" > /dev/null 2>&1
        printf "%b\n" "${GREEN}Docker group permissions applied for this session.${RC}"
    else
        printf "%b\n" "${YELLOW}NOTE: You'll need to log out and log back in, or run 'newgrp docker' in your terminal to apply the group changes.${RC}"
    fi
    
    printf "%b\n" "${GREEN}Current user added to the docker group successfully.${RC}"
}

checkEnv
checkEscalationTool
install_components
docker_permission