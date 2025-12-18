# Minimal, reproducible zsh config
export EDITOR=vim
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_GLOB AUTO_CD
setopt NO_BEEP

# Homebrew (if present)
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# mise (rtx) runtimes
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# direnv per-directory envs
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# fzf keybindings/completion (if installed later)
if command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix 2>/dev/null)/opt/fzf"
  [ -f "$FZF_BASE/shell/key-bindings.zsh" ] && source "$FZF_BASE/shell/key-bindings.zsh"
  [ -f "$FZF_BASE/shell/completion.zsh" ] && source "$FZF_BASE/shell/completion.zsh"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Aliases and safe wrappers
alias ll="ls -lah"

# Ollama aliases (if installed)
if command -v ollama >/dev/null 2>&1; then
  alias ollama-list="ollama list"
  alias ollama-ps="ollama ps"
  alias ollama-pull="ollama pull"
fi

cat() {
  if command -v bat >/dev/null 2>&1; then
    bat --paging=never "$@"
  else
    command cat "$@"
  fi
}

ls() {
  if command -v eza >/dev/null 2>&1; then
    eza --group-directories-first --icons=auto "$@"
  else
    command ls "$@"
  fi
}

# Completion and keybindings
autoload -Uz compinit && compinit -i
bindkey -e
