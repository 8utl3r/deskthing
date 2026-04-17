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

# Homebrew `dotnet`: global tool apphosts (ilspycmd) resolve the runtime via DOTNET_ROOT,
# not PATH — without this they only probe /usr/local/share/dotnet and fail.
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -x "${HOMEBREW_PREFIX}/opt/dotnet/libexec/dotnet" ]; then
  export DOTNET_ROOT="${HOMEBREW_PREFIX}/opt/dotnet/libexec"
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

# Ollama configuration (if installed)
if command -v ollama >/dev/null 2>&1; then
  # Optimize memory usage for 18GB RAM system
  export OLLAMA_KV_CACHE_TYPE=q8_0
  # Keep model loaded for instant responses
  export OLLAMA_KEEP_ALIVE=24h
  
  # Enable Tailscale/network access (uncomment to allow remote connections)
  # export OLLAMA_HOST=0.0.0.0:11434
  # See: ~/dotfiles/ollama/tailscale_access.md for setup instructions
  
  # Aliases
  alias ollama-list="ollama list"
  alias ollama-ps="ollama ps"
  alias ollama-pull="ollama pull"
  # Atlas (Private Life Manager) aliases
  alias atlas="ollama run atlas"
  alias atlas-prompt="$EDITOR $HOME/dotfiles/ollama/system_prompt.txt"
  alias atlas-reload="cd $HOME/dotfiles/ollama && ollama rm atlas 2>/dev/null; ollama create atlas -f Modelfile.dolphin-mistral-nemo"
  alias atlas-cli="$HOME/dotfiles/ollama/atlas-cli.sh"
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

# Atlas Proxy configuration
if [ -f "$HOME/Library/LaunchAgents/homebrew.mxcl.atlas-proxy.plist" ]; then
  alias atlas-proxy-start="launchctl load -w $HOME/Library/LaunchAgents/homebrew.mxcl.atlas-proxy.plist 2>/dev/null || launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/homebrew.mxcl.atlas-proxy.plist"
  alias atlas-proxy-stop="launchctl unload -w $HOME/Library/LaunchAgents/homebrew.mxcl.atlas-proxy.plist 2>/dev/null || launchctl bootout gui/$(id -u)/homebrew.mxcl.atlas-proxy"
  alias atlas-proxy-restart="atlas-proxy-stop && sleep 1 && atlas-proxy-start"
  alias atlas-proxy-status="launchctl list | grep atlas-proxy || echo 'Atlas proxy not running'"
  alias atlas-proxy-logs="tail -f /opt/homebrew/var/log/atlas-proxy.log"
fi
export PATH="$HOME/.local/bin:$PATH"
# .NET global tools (e.g. ilspycmd from `dotnet tool install -g`)
export PATH="$PATH:$HOME/.dotnet/tools"
# ilspycmd targets .NET 8; Homebrew `dotnet` is .NET 10 — roll forward is supported
export DOTNET_ROLL_FORWARD=LatestMajor
# Factorio agent CLI (fa); controller has static DHCP lease
[ -d "$HOME/dotfiles/factorio/agent_scripts" ] && export PATH="$HOME/dotfiles/factorio/agent_scripts:$PATH"
export CONTROLLER_URL="${CONTROLLER_URL:-http://192.168.0.158:8080}"

# Headscale CLI (remote control of Headscale on TrueNAS)
# See ~/dotfiles/docs/networking/headscale-cli-setup.md
if command -v headscale >/dev/null 2>&1; then
  HEADSCALE_ENV="$HOME/dotfiles/headscale/.env"
  if [ -f "$HEADSCALE_ENV" ]; then
    set -a
    source "$HEADSCALE_ENV"
    set +a
  fi
  alias headscale-users="headscale users list"
  alias headscale-nodes="headscale nodes list"
  alias headscale-routes="headscale nodes list-routes"
fi