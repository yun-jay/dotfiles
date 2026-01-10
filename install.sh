#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles..."

# Detect package manager
if command -v brew &> /dev/null; then
    PM="brew"
elif command -v apt &> /dev/null; then
    PM="apt"
else
    echo "No supported package manager found (brew or apt)"
    exit 1
fi

install_pkg() {
    if ! command -v "$1" &> /dev/null; then
        echo "Installing $1..."
        if [ "$PM" = "brew" ]; then
            brew install "$1"
        else
            sudo apt install -y "$1"
        fi
    else
        echo "$1 already installed"
    fi
}

# Install dependencies
install_pkg stow
install_pkg nvim
install_pkg tmux

# Stow packages
cd "$DOTFILES"
stow nvim tmux

# Install TPM (Tmux Plugin Manager) and plugins
if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "Installing tmux plugins..."
    ~/.tmux/plugins/tpm/bin/install_plugins
else
    echo "TPM already installed"
fi

# Ensure ~/.local/bin is in PATH
mkdir -p ~/.local/bin
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "Added ~/.local/bin to PATH in .zshrc"
fi

# Install wt from source
echo "Installing wt..."
if command -v go &> /dev/null; then
    WR_TMP=$(mktemp -d)
    git clone https://github.com/yun-jay/wt.git "$WR_TMP/wt"
    cd "$WR_TMP/wt"
    make install
    rm -rf "$WR_TMP"
    echo "wt installed successfully"
else
    echo "Go not found - skipping wt installation"
    echo "Install Go and run: git clone https://github.com/yun-jay/wt.git && cd wt && make install"
fi

echo "Done!"
echo "Run 'source ~/.zshrc' or restart your terminal"
