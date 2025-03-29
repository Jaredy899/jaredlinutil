#!/bin/sh -e

. ../../common-script.sh

installJava() {
    if ! command -v java >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Java...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed jdk-openjdk
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y java-latest-openjdk-devel
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y default-jdk
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y java-17-openjdk-devel
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add openjdk17
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S openjdk
                ;;
            *)
                printf "%b\n" "${RED}No package manager installation available for Java${RC}"
                return 1
                ;;
        esac
        
        # Verify installation
        if command -v java >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Java installed successfully. Version: $(java -version 2>&1 | head -n 1)${RC}"
            # Set JAVA_HOME if not already set
            if [ -z "$JAVA_HOME" ]; then
                JAVA_PATH=$(which java)
                JAVA_LINK=$(readlink -f "$JAVA_PATH")
                JAVA_BIN_DIR=$(dirname "$JAVA_LINK")
                JAVA_HOME=$(dirname "$JAVA_BIN_DIR")
                
                # Add to profile
                {
                    echo ''
                    echo '# Java'
                    echo "export JAVA_HOME=$JAVA_HOME"
                    echo 'export PATH=$PATH:$JAVA_HOME/bin'
                } >> "$HOME/.profile"
                
                printf "%b\n" "${CYAN}JAVA_HOME set to $JAVA_HOME${RC}"
            fi
        else
            printf "%b\n" "${RED}Java installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Java is already installed. Version: $(java -version 2>&1 | head -n 1)${RC}"
    fi
}

installMaven() {
    if ! command -v mvn >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Maven...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed maven
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y maven
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y maven
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y maven
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add maven
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S apache-maven
                ;;
            *)
                printf "%b\n" "${YELLOW}No package manager installation available for Maven${RC}"
                return 0
                ;;
        esac
        
        # Verify installation
        if command -v mvn >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Maven installed successfully. Version: $(mvn -version | head -n 1)${RC}"
        else
            printf "%b\n" "${YELLOW}Maven installation skipped.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Maven is already installed. Version: $(mvn -version | head -n 1)${RC}"
    fi
}

installGradle() {
    if ! command -v gradle >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Gradle...${RC}"

        # First try package manager installation
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed gradle
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gradle
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gradle
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gradle
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add gradle
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -S gradle
                ;;
            *)
                printf "%b\n" "${YELLOW}No package manager installation available for Gradle${RC}"
                return 0
                ;;
        esac
        
        # Verify installation
        if command -v gradle >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Gradle installed successfully. Version: $(gradle -version | grep Gradle | head -n 1)${RC}"
        else
            printf "%b\n" "${YELLOW}Gradle installation skipped.${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Gradle is already installed. Version: $(gradle -version | grep Gradle | head -n 1)${RC}"
    fi
}

checkEnv
checkEscalationTool
installJava
installMaven
installGradle 