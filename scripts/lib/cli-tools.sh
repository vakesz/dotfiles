#!/usr/bin/env bash
# The CLI tools the Brewfile installs, for linux.sh (what to install) and
# doctor.sh (what to expect on PATH). doctor runs under macOS /bin/bash, so
# keep this bash 3.2 compatible.

[[ -n "${__DOTFILES_CLI_TOOLS_LOADED:-}" ]] && return 0
__DOTFILES_CLI_TOOLS_LOADED=1

# CLI tools from the Brewfile, one row each:
#   tool|commands|apt-get|dnf|zypper|pacman|upstream install page
# commands: any one on PATH means installed ("-" = check the package instead).
# Package fields list alternatives, first available wins; "-" = never install
# from that repo. Whether a repo carries a name is probed at install time, so
# an older release that lacks a package just falls through to the hint.
CLI_TOOL_ROWS=(
    "bat|bat batcat|bat|bat|bat|bat|https://github.com/sharkdp/bat#installation"
    "bun|bun|bun|bun|bun|bun|https://bun.sh/docs/installation"
    "ccache|ccache|ccache|ccache|ccache|ccache|https://ccache.dev/download.html"
    "direnv|direnv|direnv|direnv|direnv|direnv|https://direnv.net/docs/installation.html"
    "eza|eza|eza|eza|eza|eza|https://github.com/eza-community/eza/blob/main/INSTALL.md"
    "fd|fd fdfind|fd-find|fd-find|fd|fd|https://github.com/sharkdp/fd#installation"
    "fzf|fzf|fzf|fzf|fzf|fzf|https://github.com/junegunn/fzf#installation"
    "git-lfs|git-lfs|git-lfs|git-lfs|git-lfs|git-lfs|https://git-lfs.com"
    "jq|jq|jq|jq|jq|jq|https://jqlang.org/download/"
    # Debian/Ubuntu ship an end-of-life node (18 on Ubuntu 24.04, 12 on 22.04).
    "node|node|-|nodejs|-|nodejs|https://nodejs.org/en/download (fnm or NodeSource)"
    "pnpm|pnpm|pnpm|pnpm|pnpm|pnpm|https://pnpm.io/installation"
    "ripgrep|rg|ripgrep|ripgrep|ripgrep|ripgrep|https://github.com/BurntSushi/ripgrep#installation"
    # Fedora's package ships only rustup-init; running it installs rustup.
    "rustup|rustup rustup-init|rustup|rustup|rustup|rustup|https://rustup.rs"
    "starship|starship|starship|starship|starship|starship|https://starship.rs/guide/#step-1-install-starship"
    "tealdeer|tldr|tealdeer tldr|tealdeer tldr|tealdeer|tealdeer|https://tealdeer-rs.github.io/tealdeer/installing.html"
    "uv|uv|uv|uv|uv|uv|https://docs.astral.sh/uv/getting-started/installation/"
    # The Brewfile's yq is mikefarah's. Debian's yq package is an unrelated
    # Python jq wrapper with a different CLI; Arch ships mikefarah's as go-yq.
    "yq|yq|-|yq|yq|go-yq|https://github.com/mikefarah/yq#install"
    "zoxide|zoxide|zoxide|zoxide|zoxide|zoxide|https://github.com/ajeetdsouza/zoxide#installation"
    "zsh-autosuggestions|-|zsh-autosuggestions|zsh-autosuggestions|zsh-autosuggestions|zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md"
    "zsh-syntax-highlighting|-|zsh-syntax-highlighting|zsh-syntax-highlighting|zsh-syntax-highlighting|zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md"
)
readonly CLI_TOOL_ROWS

# Print the command names of every row that has them, one row per line as
# "a|b": any one of them on PATH means the tool is installed.
cli_tool_commands() {
    local row="" commands=""

    for row in "${CLI_TOOL_ROWS[@]}"; do
        IFS="|" read -r _ commands _ <<<"$row"
        [[ "$commands" != "-" ]] || continue
        printf '%s\n' "${commands// /|}"
    done
}
