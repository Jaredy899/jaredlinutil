#!/bin/sh

. ../common-script.sh

# Function to install zsh
installZsh() {
  if ! command_exists zsh; then
    printf "%b\n" "${YELLOW}Installing Zsh...${RC}"
    case "$PACKAGER" in
      pacman)
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm zsh
        ;;
      apk)
        "$ESCALATION_TOOL" "$PACKAGER" add zsh
        ;;
      xbps-install)
        "$ESCALATION_TOOL" "$PACKAGER" -Sy zsh
        ;;
      *)
        "$ESCALATION_TOOL" "$PACKAGER" install -y zsh
        ;;
    esac
  else
    printf "%b\n" "${GREEN}ZSH is already installed.${RC}"
  fi
}

installFont() {
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "%b\n" "${GREEN}Font '$FONT_NAME' is installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
        unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR"/"$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
        printf "%b\n" "${GREEN}'$FONT_NAME' installed successfully.${RC}"
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship already installed${RC}"
        return
    fi

    if [ "$PACKAGER" = "eopkg" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" install -y starship || {
            printf "%b\n" "${RED}Failed to install starship with Solus!${RC}"
            exit 1
        }
    else
        curl -sSL https://starship.rs/install.sh | "$ESCALATION_TOOL" sh || {
            printf "%b\n" "${RED}Failed to install starship!${RC}"
            exit 1
        }
    fi

    if command_exists fzf; then
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$ESCALATION_TOOL" ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
        return
    fi

    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

# Function to set default shell to zsh
setDefaultShellToZsh() {
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    
    if [ -z "$ZSH_PATH" ]; then
        printf "%b\n" "${RED}Zsh is not installed!${RC}"
        return 1
    fi
    
    # Ensure zsh is in /etc/shells
    if ! grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
        printf "%b\n" "${YELLOW}Adding zsh to /etc/shells...${RC}"
        echo "$ZSH_PATH" | "$ESCALATION_TOOL" tee -a /etc/shells >/dev/null
    fi
    
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        printf "%b\n" "${YELLOW}Changing default shell to zsh for user $USER...${RC}"
        
        # Try chsh first (most common method)
        if command -v chsh >/dev/null 2>&1; then
            if chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
                printf "%b\n" "${GREEN}Default shell changed to zsh.${RC}"
            else
                # Fallback: try with sudo if regular chsh fails
                if "$ESCALATION_TOOL" chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
                    printf "%b\n" "${GREEN}Default shell changed to zsh.${RC}"
                else
                    printf "%b\n" "${YELLOW}Automatic shell change failed. Trying usermod...${RC}"
                    # Fallback: use usermod (requires root)
                    if "$ESCALATION_TOOL" usermod -s "$ZSH_PATH" "$USER" 2>/dev/null; then
                        printf "%b\n" "${GREEN}Default shell changed to zsh using usermod.${RC}"
                    else
                        printf "%b\n" "${RED}Failed to change shell automatically.${RC}"
                        printf "%b\n" "${YELLOW}Please run manually: chsh -s $ZSH_PATH${RC}"
                        printf "%b\n" "${YELLOW}Or log out and back in for changes to take effect.${RC}"
                    fi
                fi
            fi
        else
            # No chsh available, try usermod directly
            if "$ESCALATION_TOOL" usermod -s "$ZSH_PATH" "$USER" 2>/dev/null; then
                printf "%b\n" "${GREEN}Default shell changed to zsh using usermod.${RC}"
            else
                printf "%b\n" "${RED}Neither chsh nor usermod available. Please change shell manually.${RC}"
            fi
        fi
    else
        printf "%b\n" "${GREEN}Default shell is already zsh.${RC}"
    fi
}

BASE_URL="https://raw.githubusercontent.com/Jaredy899/linux/main/config_changes"
ZSHRC_URL="https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/.zshrc"

setupAndReplaceConfigs() {
    printf "%b\n" "${YELLOW}Setting up Zsh and downloading configurations...${RC}"

    # Create necessary directories
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config"

    # Download .zshrc from your mac repo
    curl -fsSL "$ZSHRC_URL" -o "$HOME/.config/zsh/.zshrc"

    # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
    [ ! -f /etc/zsh/zshenv ] && "$ESCALATION_TOOL" mkdir -p /etc/zsh && "$ESCALATION_TOOL" touch /etc/zsh/zshenv
    grep -q "ZDOTDIR" /etc/zsh/zshenv 2>/dev/null || \
        echo "export ZDOTDIR=\"$HOME/.config/zsh\"" | "$ESCALATION_TOOL" tee -a /etc/zsh/zshenv

    # Handle Alpine and Solus special cases for /etc/profile and .profile
    if [ -f /etc/alpine-release ]; then
        "$ESCALATION_TOOL" curl -sSfL -o "/etc/profile" "$BASE_URL/profile"
        "$ESCALATION_TOOL" apk add zoxide
    elif [ "$DTYPE" = "solus" ]; then
        curl -sSfL -o "$HOME/.profile" "$BASE_URL/.profile"
    fi

    # Download fastfetch and starship configs
    curl -sSfL -o "$HOME/.config/fastfetch/config.jsonc" "$BASE_URL/config.jsonc"
    curl -sSfL -o "$HOME/.config/starship.toml" "$BASE_URL/starship.toml"

    printf "%b\n" "${GREEN}Zsh and other configurations set up successfully.${RC}"
}

checkEnv
checkEscalationTool
installZsh
setDefaultShellToZsh
installFont
installStarshipAndFzf
installZoxide
setupAndReplaceConfigs 