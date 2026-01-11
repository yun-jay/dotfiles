# Dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

### Cross-platform (macOS + Linux)

- `nvim` - Neovim configuration with Lazy.nvim, LSP, Telescope, etc.
- `tmux` - Tmux configuration with TPM plugins
- `claude` - Claude Code CLI settings and hooks

### macOS only

- `karabiner` - Karabiner-Elements keyboard remapping (Caps Lock → Control, Cmd+Ctrl+H/L for Space switching)

## Quick Install

```bash
git clone https://github.com/yun-jay/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script automatically detects your OS:
- **macOS**: Installs all packages including Karabiner-Elements
- **Linux**: Installs only cross-platform packages

## Manual Setup

### Prerequisites

```bash
# macOS
brew install stow nvim tmux

# Ubuntu/Debian
sudo apt install stow nvim tmux
```

### Install configs

```bash
cd ~/dotfiles

# Cross-platform
stow nvim tmux claude

# macOS only
stow karabiner
```

### Uninstall

```bash
cd ~/dotfiles
stow -D nvim tmux claude karabiner
```

## Updating

Since configs are symlinked, changes take effect immediately after pulling:

```bash
cd ~/dotfiles
git pull
```

## How Stow Works

Stow creates symlinks from your home directory to the dotfiles repo. Each package directory mirrors the home directory structure:

```
dotfiles/
├── nvim/.config/nvim/          →  ~/.config/nvim
├── tmux/.tmux.conf             →  ~/.tmux.conf
├── claude/.claude/             →  ~/.claude
└── karabiner/.config/karabiner →  ~/.config/karabiner
```

## Karabiner-Elements (macOS)

Custom keyboard mappings:
- **Caps Lock → Control** - More ergonomic modifier key
- **Cmd+Ctrl+H** - Switch to left Space
- **Cmd+Ctrl+L** - Switch to right Space

## wt (Git Worktree Manager)

The `wt` tool is installed automatically if Go is available, or manually from [yun-jay/wt](https://github.com/yun-jay/wt):

```bash
git clone https://github.com/yun-jay/wt.git
cd wt
make install
```

Requires Go 1.21+.
