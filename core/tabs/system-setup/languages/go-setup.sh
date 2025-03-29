#!/bin/sh -e

. ../common-script.sh

installGo() {
    if ! command -v go >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Fetching latest Go version information...${RC}"
        
        # Determine architecture
        ARCH="$(uname -m)"
        if [ "$ARCH" = "x86_64" ]; then
            GO_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ]; then
            GO_ARCH="arm64"
        else
            printf "%b\n" "${RED}Unsupported architecture: ${ARCH}${RC}"
            return 1
        fi
        
        # Get the latest version from Go website
        LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
        LATEST_VERSION=${LATEST_VERSION#go}  # Remove 'go' prefix
        
        printf "%b\n" "${YELLOW}Installing latest Go version: ${LATEST_VERSION}...${RC}"
        
        # Download Go
        DOWNLOAD_URL="https://go.dev/dl/go${LATEST_VERSION}.linux-${GO_ARCH}.tar.gz"
        TARBALL="go${LATEST_VERSION}.linux-${GO_ARCH}.tar.gz"
        
        printf "%b\n" "${YELLOW}Downloading Go from ${DOWNLOAD_URL}...${RC}"
        curl -LO "$DOWNLOAD_URL"
        
        # Remove previous installation if it exists
        printf "%b\n" "${YELLOW}Removing any previous Go installation...${RC}"
        "$ESCALATION_TOOL" rm -rf /usr/local/go
        
        # Extract Go to /usr/local
        printf "%b\n" "${YELLOW}Extracting Go to /usr/local...${RC}"
        "$ESCALATION_TOOL" tar -C /usr/local -xzf "$TARBALL"
        
        # Setup PATH in profile
        printf "%b\n" "${YELLOW}Setting up PATH environment variable...${RC}"
        if ! grep -q "/usr/local/go/bin" /etc/profile; then
            printf "\n# Go PATH\nexport PATH=\$PATH:/usr/local/go/bin\n" | "$ESCALATION_TOOL" tee -a /etc/profile
        fi
        
        # Add to current PATH
        export PATH=$PATH:/usr/local/go/bin
        
        # Clean up
        rm -f "$TARBALL"
        
        # Verify installation
        if command -v go >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}Go installed successfully. Version: $(go version)${RC}"
            printf "%b\n" "${CYAN}To start using Go in this session, run: export PATH=\$PATH:/usr/local/go/bin${RC}"
            printf "%b\n" "${CYAN}Go will be available in your PATH after you log in again.${RC}"
        else
            printf "%b\n" "${RED}Go installation failed.${RC}"
            return 1
        fi
    else
        printf "%b\n" "${GREEN}Go is already installed. Version: $(go version)${RC}"
    fi
}

checkEnv
checkEscalationTool
installGo 