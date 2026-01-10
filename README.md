# Dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

- `nvim` - Neovim configuration
- `tmux` - Tmux configuration

## Quick Install

```bash
git clone https://github.com/yun-jay/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Manual Setup

### Prerequisites

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow
```

### Install all configs

```bash
cd ~/dotfiles
stow nvim tmux
```

### Install individual configs

```bash
cd ~/dotfiles
stow nvim    # Only neovim
stow tmux    # Only tmux
```

### Uninstall

```bash
cd ~/dotfiles
stow -D nvim tmux
```

## wt (Git Worktree Manager)

The `wt` tool is installed separately from [yun-jay/wt](https://github.com/yun-jay/wt):

```bash
git clone https://github.com/yun-jay/wt.git
cd wt
make install
```

Requires Go 1.21+.
