# Safe, minimal zshrc
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY
export EDITOR=vim

# Prefer Homebrew paths if available
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Starship prompt if installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# mise (rtx) for runtimes if installed
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

alias ll="ls -lah"
