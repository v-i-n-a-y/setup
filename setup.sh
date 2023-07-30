#!/bin/bash

# Checks if homebrew is installed
is_homebrew_installed() {
    if command -v brew &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Installs Homebrew
install_homebrew() {
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Installs fish
install_fish() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        sudo apt-get update
        sudo apt-get install -y fish
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install fish
    else
        echo "Unsupported operating system. Cannot install fish."
        exit 1
    fi
}

# Installs nvim
install_neovim() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        if command -v nvim &>/dev/null; then
            echo "Neovim is already installed."
        else
            sudo apt-get update
            sudo apt-get install -y neovim
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v nvim &>/dev/null; then
            echo "Neovim is already installed."
        else
            brew install neovim
        fi
    else
        echo "Unsupported operating system. Cannot install neovim."
        exit 1
    fi
}

install_usersettings(){
		
		echo "Installing neovim user settings"
		sudo cp ./nvim/* ~/.config/nvim/

		echo "Installing fish settings"
		sudo cp ./fish/* ~/.config/fish/
		
		echo "Changing default shell to fish"
		chsh -s "$(which fish)"

}

install(){

    echo "Installing fish shell..."
    install_fish

    echo "Installing neovim..."
    install_neovim

	echo "Installing user settings"
	install_usersettings

}


# Main script
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"

    if is_homebrew_installed; then
        echo "Homebrew is already installed."
    else
        echo "Installing Homebrew..."
        install_homebrew

        if is_homebrew_installed; then
            echo "Homebrew installed successfully."
        else
            echo "Error: Homebrew installation failed."
            exit 1
        fi
    fi
		install()

elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "Detected Linux"

	install()
else
    echo "Unsupported operating system. Cannot proceed with installation."
    exit 1
fi

