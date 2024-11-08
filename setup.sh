#!/bin/bash

# Vinay's little setup tool for Linux and MacOS
# I move computers or crash them too often and
# I am lazy

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Installs Homebrew
install_homebrew() {
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed."
    fi
}

# Installs fish
install_fish() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y fish
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install fish
    else
        echo "Unsupported OS for Fish installation."
        exit 1
    fi
}

# Installs Neovim
install_neovim() {
    if command_exists nvim; then
        echo "Neovim is already installed."
    else
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "Installing Neovim via apt-get..."
            sudo apt-get update
            sudo apt-get install -y neovim

            # Install latest Neovim from GitHub
            # Can remove is apt-get starts having the latest version...
            echo "Installing the latest Neovim from GitHub..."
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
            tar -xvf nvim-linux64.tar.gz
            sudo mv nvim-linux64/bin/nvim /usr/local/bin
            rm -rf nvim-linux64 nvim-linux64.tar.gz
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install neovim
        else
            echo "Unsupported OS for Neovim installation."
            exit 1
        fi
    fi
}

# Installs GCC
install_gcc() {
    if ! command_exists gcc; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y build-essential
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gcc
        else
            echo "Unsupported OS for GCC installation."
            exit 1
        fi
    else
        echo "GCC is already installed."
    fi
}

# Installs tmux
install_tmux() {
    if ! command_exists tmux; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y tmux
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install tmux
        else
            echo "Unsupported OS for tmux installation."
            exit 1
        fi
    else
        echo "tmux is already installed."
    fi
}

# Installs rclone
install_rclone() {
    if ! command_exists rclone; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl https://rclone.org/install.sh | sudo bash
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install rclone
        else
            echo "Unsupported OS for rclone installation."
            exit 1
        fi
    else
        echo "rclone is already installed."
    fi
}

install_rust() {
    if ! command_exists rustc; then
        if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        else
            echo "Unsupported OS for Rust installation."
            exit 1
        fi
    else
        echo "Rust is already installed."
    fi
}

# Installs Miniconda3
install_miniconda() {
    if command_exists conda; then
        echo "Miniconda is already installed."
    else
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "Downloading and installing Miniconda for Linux..."
            curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
            chmod +x Miniconda3-latest-Linux-x86_64.sh
            ./Miniconda3-latest-Linux-x86_64.sh -b -f
            rm -f Miniconda3-latest-Linux-x86_64.sh
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Downloading and installing Miniconda for macOS..."
            curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
            chmod +x Miniconda3-latest-MacOSX-x86_64.sh
            ./Miniconda3-latest-MacOSX-x86_64.sh -b -f
            rm -f Miniconda3-latest-MacOSX-x86_64.sh
        else
            echo "Unsupported OS for Miniconda installation."
            exit 1
        fi
    fi
}


# Installs user settings
install_user_settings() {
    echo "Installing Neovim user settings..."
    mkdir -p ~/.config/nvim
    cp ./nvim/* ~/.config/nvim/

    echo "Installing Fish settings..."
    mkdir -p ~/.config/fish
    cp ./fish/* ~/.config/fish/

    if ! grep -q "$(which fish)" /etc/shells; then
        echo "Adding Fish to /etc/shells..."
        echo "$(which fish)" | sudo tee -a /etc/shells > /dev/null
    else
        echo "Fish shell is already in /etc/shells."
    fi

    echo "Changing default shell to Fish..."
    chsh -s "$(which fish)"
}

# Install all required packages and configurations
install() {
    echo "Installing Fish shell..."
    install_fish

    echo "Installing Neovim..."
    install_neovim

    echo "Installing Miniconda..."
    install_miniconda

    echo "Installing tmux..."
    install_tmux

    echo "Installing rclone..."
    install_rclone

    echo "Installing rust..."
    install_rust

    echo "Installing GCC..."
    install_gcc

    echo "Installing user settings..."
    install_user_settings
}

# Main script logic
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
    install_homebrew
    install

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux"
    install

else
    echo "Unsupported operating system. Cannot proceed with installation."
    echo " Obviously I don't like Windows..."
    exit 1
fi

