#!/usr/bin/env bash

# Vinay's bootstrap for fresh Linux / macOS boxes.
# I move computers or crash them too often. I am lazy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
STOW_PACKAGES=(nvim fish git tmux)

is_macos() { [[ "$OSTYPE" == "darwin"* ]]; }
is_linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }
command_exists() { command -v "$1" &>/dev/null; }

install_homebrew() {
    if command_exists brew; then
        echo "Homebrew already installed."
    else
        echo "Installing Homebrew..."
        # Download first and check curl's exit status. Running the installer via
        # `bash -c "$(curl ...)"` hides a curl failure: the substitution yields ""
        # and `bash -c ""` exits 0, so a network error surfaces later as a
        # confusing "brew: command not found".
        local installer
        installer="$(mktemp)"
        if ! curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
            echo "Failed to download the Homebrew installer." >&2
            rm -f "$installer"
            exit 1
        fi
        /bin/bash "$installer"
        rm -f "$installer"
    fi
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_brew_bundle() {
    echo "Installing brew formulae from Brewfile..."
    brew bundle install --file="$SCRIPT_DIR/Brewfile"
}

install_apt_packages() {
    sudo apt-get update
    sudo apt-get install -y \
        fish tmux direnv stow rclone build-essential git curl
    # These live in Ubuntu 'universe' / only-recent Debian. Install them in a
    # separate call so one missing package on an older or minimal box doesn't
    # abort the whole bootstrap before dotfiles/neovim/uv/gh/rust are set up.
    sudo apt-get install -y xclip wl-clipboard pre-commit tree \
        || echo "Warning: some optional apt packages were unavailable; continuing."
}

install_neovim_linux() {
    if command_exists nvim; then
        echo "Neovim already installed."
        return
    fi
    local arch tarball tmp
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  tarball="nvim-linux-x86_64.tar.gz" ;;
        aarch64) tarball="nvim-linux-arm64.tar.gz" ;;
        *) echo "Unsupported arch for Neovim: $arch"; exit 1 ;;
    esac
    echo "Installing Neovim from GitHub ($tarball)..."
    tmp="$(mktemp -d)"
    curl -fL -o "$tmp/$tarball" "https://github.com/neovim/neovim/releases/latest/download/$tarball"
    tar -xzf "$tmp/$tarball" -C "$tmp"
    sudo cp -R "$tmp"/nvim-linux-*/. /usr/local/
    rm -rf "$tmp"
}

install_uv_linux() {
    if command_exists uv; then
        echo "uv already installed."
        return
    fi
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_gh_linux() {
    if command_exists gh; then
        echo "gh already installed."
        return
    fi
    echo "Adding GitHub CLI apt repo and installing gh..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
}

install_rust() {
    if command_exists rustc; then
        echo "Rust already installed."
        return
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

ensure_fish_in_shells() {
    local fish_path
    fish_path="$(command -v fish)"
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "Adding $fish_path to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi
}

# Move any pre-existing regular files at stow's targets out of the way so stow can take over.
park_existing_targets() {
    local pkg src_root rel target backup ts
    ts="$(date +%Y%m%d%H%M%S)"
    for pkg in "${STOW_PACKAGES[@]}"; do
        src_root="$DOTFILES_DIR/$pkg"
        [[ -d "$src_root" ]] || continue
        while IFS= read -r -d '' src; do
            rel="${src#$src_root/}"
            target="$HOME/$rel"
            if [[ -e "$target" && ! -L "$target" ]]; then
                # Skip if the target already resolves to the repo's own file through a
                # folded parent directory symlink (stow tree-folding). Without this,
                # `mv` would rename the repo's tracked file, corrupting the checkout.
                if [[ "$target" -ef "$src" ]]; then
                    continue
                fi
                backup="$target.pre-stow.$ts"
                echo "Backing up $target -> $backup"
                mv "$target" "$backup"
            fi
        done < <(find "$src_root" -type f -print0)
    done
}

link_dotfiles() {
    if ! command_exists stow; then
        echo "stow not installed — cannot link dotfiles."
        exit 1
    fi
    park_existing_targets
    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "${STOW_PACKAGES[@]}"
    echo "Dotfiles linked via stow."
}

if is_macos; then
    echo "Detected macOS"
    install_homebrew
    install_brew_bundle
    install_rust
elif is_linux; then
    echo "Detected Linux"
    install_apt_packages
    install_neovim_linux
    install_uv_linux
    install_gh_linux
    install_rust
else
    echo "Unsupported OS."
    exit 1
fi

ensure_fish_in_shells
link_dotfiles

# If this repo is a git checkout and pre-commit is available, wire up the hooks.
if [[ -d "$SCRIPT_DIR/.git" ]] \
    && command_exists pre-commit \
    && [[ -f "$SCRIPT_DIR/.pre-commit-config.yaml" ]]; then
    echo "Installing pre-commit hooks for this repo..."
    (cd "$SCRIPT_DIR" && pre-commit install)
fi

echo
echo "Done."
echo "  - Make fish login shell: chsh -s \"\$(command -v fish)\""
echo "  - Bootstrap SSH key:     $SCRIPT_DIR/scripts/ssh-bootstrap.sh"
echo "  - Schedule OS updates:   $SCRIPT_DIR/cron/install.sh"
