# PATH
export PATH="$PATH:$HOME/bin"
export PATH="$HOME/.local/bin:$PATH"

. "$HOME/.local/bin/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# bash
export PATH="/opt/homebrew/bin:$PATH"

# npm
export PATH=$PATH:$(npm bin -g)

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Custom completions
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# Plugins (installed via brew)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Ctrl+F to accept autosuggestion
bindkey '^f' autosuggest-accept

# Secrets management (Vaultwarden)
# Set BW_SERVER to your Vaultwarden URL before using
source ~/.zsh/functions/secrets.zsh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"

# Local machine-specific config (not tracked by git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
