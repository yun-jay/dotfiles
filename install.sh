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
# Neovim (different package name on apt vs brew)
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    if [ "$PM" = "brew" ]; then
        brew install nvim
    else
        sudo apt install -y neovim
    fi
else
    echo "neovim already installed"
fi
install_pkg tmux
install_pkg fzf
install_pkg zsh-autosuggestions
install_pkg zsh-syntax-highlighting
install_pkg gh
install_pkg jq
# Eternal Terminal (requires tap)
if ! command -v et &> /dev/null; then
    echo "Installing eternal-terminal..."
    if [ "$PM" = "brew" ]; then
        brew install MisterTea/et/et
    fi
else
    echo "eternal-terminal already installed"
fi
# nvm (not available via apt, install via curl)
if [ "$PM" = "brew" ]; then
    install_pkg nvm
elif [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    echo "nvm already installed"
fi
install_pkg ripgrep

# Install Node.js via nvm (not Homebrew)
export NVM_DIR="$HOME/.nvm"
if [ "$PM" = "brew" ]; then
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
else
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
fi

if ! nvm list 22 &> /dev/null; then
    echo "Installing Node.js 22 via nvm..."
    nvm install 22
    nvm alias default 22
else
    echo "Node.js 22 already installed via nvm"
fi
nvm use default

# Install typescript-language-server via npm
if ! command -v typescript-language-server &> /dev/null; then
    echo "Installing typescript-language-server..."
    npm install -g typescript-language-server typescript
else
    echo "typescript-language-server already installed"
fi

# Install Bitwarden CLI
if ! command -v bw &> /dev/null; then
    echo "Installing Bitwarden CLI..."
    if [ "$PM" = "brew" ]; then
        brew install bitwarden-cli
    else
        sudo snap install bw
    fi
else
    echo "Bitwarden CLI already installed"
fi

# Install go-task
if ! command -v task &> /dev/null; then
    echo "Installing go-task..."
    if [ "$PM" = "brew" ]; then
        brew install go-task
    else
        sudo sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
    fi
else
    echo "go-task already installed"
fi

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "Claude Code already installed"
fi

# Install pi coding agent
if ! command -v pi &> /dev/null; then
    echo "Installing pi coding agent..."
    npm install -g @earendil-works/pi-coding-agent
else
    echo "pi already installed"
fi

# Install pi plugins (idempotent; regenerates ~/.pi/agent/npm/)
echo "Installing pi plugins..."
for plugin in \
    npm:pi-fff \
    npm:pi-librarian \
    npm:@fnnm/pi-session-breakdown \
    npm:pi-finder-subagent \
    npm:pi-mcp-adapter \
    npm:pi-subagents \
    npm:context-mode \
    npm:@hypabolic/pi-hypa; do
    pi install "$plugin"
done

# Patch @fnnm/pi-session-breakdown: upstream (only v0.1.0 exists on npm/git) is
# a broken fork — index.ts imports "../shared/lib.ts" (never published) and its
# lib.ts is missing the extractCostTotal/formatUsd helpers. Fix the import path
# and restore the two helpers (taken from the original mitsuhiko/agent-stuff).
SB="$HOME/.pi/agent/npm/node_modules/@fnnm/pi-session-breakdown"
if [ -d "$SB" ]; then
    echo "Patching @fnnm/pi-session-breakdown..."
    sed -i.bak 's#\.\./shared/lib\.ts#./lib.ts#' "$SB/index.ts" && rm -f "$SB/index.ts.bak"
    if ! grep -q "extractCostTotal" "$SB/lib.ts"; then
        cat >> "$SB/lib.ts" <<'SBEOF'

export function formatUsd(cost: number): string {
	if (!Number.isFinite(cost)) return "$0.00";
	if (cost >= 1) return `$${cost.toFixed(2)}`;
	if (cost >= 0.1) return `$${cost.toFixed(3)}`;
	return `$${cost.toFixed(4)}`;
}

export function extractCostTotal(usage: unknown): number {
	if (!usage) return 0;
	const c = (usage as Record<string, unknown>)?.cost;
	if (typeof c === "number") return Number.isFinite(c) ? c : 0;
	if (typeof c === "string") {
		const n = Number(c);
		return Number.isFinite(n) ? n : 0;
	}
	const t = (c as Record<string, unknown>)?.total;
	if (typeof t === "number") return Number.isFinite(t) ? t : 0;
	if (typeof t === "string") {
		const n = Number(t);
		return Number.isFinite(n) ? n : 0;
	}
	return 0;
}
SBEOF
    fi
fi

# Remove existing configs to avoid stow conflicts
rm -f ~/.claude/settings.json
rm -f ~/.zshrc
rm -rf ~/.zsh
rm -f ~/.pi/agent/settings.json

# Stow common packages
cd "$DOTFILES"
stow nvim tmux claude agents herdr zsh task pi

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

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

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

# Setup Go paths
mkdir -p ~/go/bin
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

install_pkg make

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

    # OrbStack for Docker and Linux VMs
    if [ ! -d "/Applications/OrbStack.app" ]; then
        echo "Installing OrbStack..."
        brew install --cask orbstack
    else
        echo "OrbStack already installed"
    fi

    # Ghostty terminal
    if [ ! -d "/Applications/Ghostty.app" ]; then
        echo "Installing Ghostty..."
        brew install --cask ghostty
    else
        echo "Ghostty already installed"
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
