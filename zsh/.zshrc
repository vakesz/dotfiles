# oh, hello there!

# Shell Interactivity Check
[[ $- != *i* ]] && return

have() { command -v "$1" >/dev/null 2>&1; }
alias_if_exists() { have "$2" && alias "$1"="$3"; }

# Homebrew Setup (Cross-Platform)
# Must be loaded early so $HOMEBREW_PREFIX is available for modules
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d ~/.linuxbrew ]]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi

# Modular Configuration (from .zshrc.d/)
# Load all .zsh files from ~/.zshrc.d/ directory in alphabetical order
if [[ -d "$HOME/.zshrc.d" ]]; then
    for config_file in "$HOME/.zshrc.d"/*.zsh(N); do
        source "$config_file"
    done
fi

# User Local Configuration Override
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
