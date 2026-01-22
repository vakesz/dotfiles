# .zshrc - Modular config loaded from config.d/

source "$ZDOTDIR/config.d/platform.zsh"
source "$ZDOTDIR/config.d/path.zsh"
source "$ZDOTDIR/config.d/env.zsh"
source "$ZDOTDIR/config.d/plugins.zsh"
source "$ZDOTDIR/config.d/completion.zsh"
source "$ZDOTDIR/config.d/aliases.zsh"

# Oh My Posh (cached for speed)
if have oh-my-posh; then
  omp_config="$XDG_CONFIG_HOME/oh-my-posh/zen.toml"
  omp_cache="$XDG_CACHE_HOME/zsh/oh-my-posh-init.zsh"
  omp_bin=$(command -v oh-my-posh)

  if [[ ! -f "$omp_cache" || "$omp_config" -nt "$omp_cache" || "$omp_bin" -nt "$omp_cache" ]]; then
    mkdir -p "${omp_cache:h}"
    oh-my-posh init zsh --config "$omp_config" > "$omp_cache" 2>/dev/null
  fi
  source "$omp_cache"
else
  PROMPT='%F{#9ccfd8}%~%f %F{#908caa}❯%f '
fi

# Local overrides (not tracked in git)
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
