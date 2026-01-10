#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles..."

# Install stow if not present
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    if command -v brew &> /dev/null; then
        brew install stow
    elif command -v apt &> /dev/null; then
        sudo apt install -y stow
    else
        echo "Please install GNU stow manually"
        exit 1
    fi
fi

# Stow packages
cd "$DOTFILES"
stow nvim tmux

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
