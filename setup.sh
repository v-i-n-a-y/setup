#!/usr/bin/env bash

# Vinay's bootstrap for fresh Linux / macOS boxes.
# I move computers or crash them too often. I am lazy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
DOTFILE_PACKAGES=(nvim fish git tmux)
INSTALL_MODE="all"

is_macos() { [[ "$OSTYPE" == "darwin"* ]]; }
is_linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }
command_exists() { command -v "$1" &>/dev/null; }

# Ask up front whether to install every dependency automatically, or confirm
# each one individually. Defaults to "everything" when not run interactively
# (e.g. piped from curl) so the script never hangs on a read.
prompt_install_mode() {
    if [[ ! -t 0 ]]; then
        INSTALL_MODE="all"
        return
    fi
    echo "How should dependencies be installed?"
    echo "  1) Install everything automatically (default)"
    echo "  2) Ask before installing each dependency"
    local choice
    read -rp "Choice [1]: " choice
    if [[ "$choice" == "2" ]]; then
        INSTALL_MODE="ask"
        echo "Will ask before installing each dependency."
    else
        INSTALL_MODE="all"
    fi
}

# Returns success if $1 should be installed: always in "all" mode, otherwise
# prompts and returns the user's answer (default yes).
should_install() {
    [[ "$INSTALL_MODE" == "all" ]] && return 0
    local reply
    read -rp "Install $1? [Y/n] " reply
    [[ ! "$reply" =~ ^[Nn] ]]
}

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
    if [[ "$INSTALL_MODE" == "all" ]]; then
        echo "Installing brew formulae from Brewfile..."
        brew bundle install --file="$SCRIPT_DIR/Brewfile"
        return
    fi
    local pkg
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if should_install "$pkg"; then
            brew install "$pkg"
        else
            echo "Skipping $pkg"
        fi
    done < <(sed -nE 's/^brew "([^"]+)".*/\1/p' "$SCRIPT_DIR/Brewfile")
}

install_apt_packages() {
    sudo apt-get update
    # Split into required vs. Ubuntu 'universe' / only-recent-Debian packages so
    # one missing optional package on an older or minimal box doesn't abort the
    # whole bootstrap before dotfiles/neovim/uv/gh/rust are set up.
    local required=(fish tmux direnv rclone build-essential git curl)
    local optional=(xclip wl-clipboard pre-commit tree)

    if [[ "$INSTALL_MODE" == "all" ]]; then
        sudo apt-get install -y "${required[@]}"
        sudo apt-get install -y "${optional[@]}" \
            || echo "Warning: some optional apt packages were unavailable; continuing."
        return
    fi

    local pkg
    for pkg in "${required[@]}" "${optional[@]}"; do
        if should_install "$pkg"; then
            sudo apt-get install -y "$pkg" \
                || echo "Warning: $pkg was unavailable; continuing."
        else
            echo "Skipping $pkg"
        fi
    done
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

# Older versions of this script symlinked dotfiles into place with GNU stow.
# If those symlinks (including stow's folded directory symlinks, e.g. a
# whole ~/.config/tmux pointing into this repo) are still around, remove
# them first so real files/directories can take their place below.
unstow_legacy_symlinks() {
    command_exists stow || return 0
    stow --dir="$DOTFILES_DIR" --target="$HOME" -D "${DOTFILE_PACKAGES[@]}" 2>/dev/null \
        && echo "Removed legacy stow symlinks." || true
}

# Copy (not symlink) every dotfile into $HOME, so the repo checkout can be
# deleted afterwards without taking any live config with it. Any pre-existing
# file that differs from the repo's copy is backed up first, so nothing on
# disk is destroyed silently.
copy_dotfiles() {
    local pkg src_root rel target backup ts
    unstow_legacy_symlinks
    ts="$(date +%Y%m%d%H%M%S)"
    for pkg in "${DOTFILE_PACKAGES[@]}"; do
        src_root="$DOTFILES_DIR/$pkg"
        [[ -d "$src_root" ]] || continue
        while IFS= read -r -d '' src; do
            rel="${src#$src_root/}"
            target="$HOME/$rel"
            mkdir -p "$(dirname "$target")"
            # A symlink is always replaced (even with identical content, since
            # copying through it would silently overwrite whatever it points
            # to elsewhere); a plain file is only backed up if it differs.
            if [[ -L "$target" ]] || { [[ -e "$target" ]] && ! cmp -s "$src" "$target"; }; then
                backup="$target.pre-setup.$ts"
                echo "Backing up $target -> $backup"
                mv "$target" "$backup"
            fi
            cp "$src" "$target"
        done < <(find "$src_root" -type f -print0)
    done
    echo "Dotfiles copied to \$HOME."
}

prompt_install_mode

if is_macos; then
    echo "Detected macOS"
    install_homebrew
    install_brew_bundle
    should_install "Rust (rustup)" && install_rust
elif is_linux; then
    echo "Detected Linux"
    install_apt_packages
    should_install "Neovim (from GitHub release)" && install_neovim_linux
    should_install "uv" && install_uv_linux
    should_install "gh (GitHub CLI)" && install_gh_linux
    should_install "Rust (rustup)" && install_rust
else
    echo "Unsupported OS."
    exit 1
fi

ensure_fish_in_shells
copy_dotfiles

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
echo "  - Set desktop wallpaper: $SCRIPT_DIR/scripts/wallpapers.sh"
echo "  - Schedule OS updates:   $SCRIPT_DIR/cron/install.sh"
