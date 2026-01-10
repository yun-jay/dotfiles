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

## Updating

### Pull latest changes

```bash
cd ~/dotfiles
git pull
```

Since configs are symlinked, changes take effect immediately.

### After adding new stow packages

```bash
cd ~/dotfiles
git pull
stow <new-package>
```

### Push local changes

```bash
cd ~/dotfiles
git add -A
git commit -m "Update configs"
git push
```

## How Stow Works

Stow creates symlinks from your home directory to the dotfiles repo. Each package directory mirrors the home directory structure:

```
dotfiles/
├── nvim/.config/nvim/    →  ~/.config/nvim
└── tmux/.tmux.conf       →  ~/.tmux.conf
```

Running `stow nvim` creates: `~/.config/nvim -> ~/dotfiles/nvim/.config/nvim`

## wt (Git Worktree Manager)

The `wt` tool is installed separately from [yun-jay/wt](https://github.com/yun-jay/wt):

```bash
git clone https://github.com/yun-jay/wt.git
cd wt
make install
```

Requires Go 1.21+.
