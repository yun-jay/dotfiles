#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Detect OS
OS="$(uname -s)"
echo "Installing dotfiles on $OS..."

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

# =============================================================================
# UNIX (Common packages for macOS and Linux)
# =============================================================================

echo ""
echo "=== Installing common packages ==="

install_pkg stow
install_pkg nvim
install_pkg tmux

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "Claude Code already installed"
fi

# Remove existing claude settings to avoid stow conflict
rm -f ~/.claude/settings.json

# Stow common packages
cd "$DOTFILES"
stow nvim tmux claude

# Install Neovim plugins
echo "Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa

# Install TPM (Tmux Plugin Manager)
if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo "TPM already installed"
fi

# Install tmux plugins
echo "Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

# Ensure ~/.local/bin is in PATH
mkdir -p ~/.local/bin
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "Added ~/.local/bin to PATH in .zshrc"
fi

# =============================================================================
# Go Installation
# =============================================================================

echo ""
echo "=== Installing Go ==="

if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    if [ "$PM" = "brew" ]; then
        brew install go
    else
        sudo apt install -y golang-go
    fi
else
    echo "Go already installed: $(go version)"
fi

# Configure Go paths in zshrc
echo "Configuring Go paths..."
mkdir -p ~/go/bin

if ! grep -q 'export GOPATH="$HOME/go"' ~/.zshrc 2>/dev/null; then
    echo 'export GOPATH="$HOME/go"' >> ~/.zshrc
    echo "Added GOPATH to .zshrc"
fi

if ! grep -q 'export PATH="$GOPATH/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.zshrc
    echo "Added Go bin to PATH in .zshrc"
fi

# Source the updated PATH for this script
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Install air (Go live reload tool)
echo "Installing air..."
if ! command -v air &> /dev/null; then
    go install github.com/air-verse/air@latest
    echo "air installed successfully"
else
    echo "air already installed"
fi

# Install wt from source
echo "Installing wt..."
if command -v go &> /dev/null; then
    WR_TMP=$(mktemp -d)
    git clone https://github.com/yun-jay/wt.git "$WR_TMP/wt"
    cd "$WR_TMP/wt"
    make install
    cd "$DOTFILES"
    rm -rf "$WR_TMP"
    echo "wt installed successfully"
else
    echo "Go not found - skipping wt installation"
    echo "Install Go and run: git clone https://github.com/yun-jay/wt.git && cd wt && make install"
fi

# =============================================================================
# macOS only
# =============================================================================

if [ "$OS" = "Darwin" ]; then
    echo ""
    echo "=== Installing macOS packages ==="

    # Karabiner-Elements for keyboard remapping
    if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
        echo "Installing Karabiner-Elements..."
        brew install --cask karabiner-elements
    else
        echo "Karabiner-Elements already installed"
    fi

    # Stow macOS packages
    cd "$DOTFILES"
    stow karabiner
fi

# =============================================================================
# Done
# =============================================================================

echo ""
echo "Done!"
echo ""
echo "IMPORTANT: Run 'source ~/.zshrc' or restart your terminal to apply PATH changes."
