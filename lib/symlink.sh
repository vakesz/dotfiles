#!/usr/bin/env bash

# Symlinking utilities

# shellcheck source=lib/platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

# Backup existing files/directories
backup_if_exists() {
    local target="$1"
    local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

    if [[ -e "$target" && ! -L "$target" ]]; then
        log "Backing up existing $target to $backup_dir"
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
    fi
}

# Create symlink with proper error handling
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir

    target_dir="$(dirname "$target")"

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # Remove existing symlink if it exists
    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    # Backup existing file/directory
    backup_if_exists "$target"

    # Create the symlink
    if ln -sf "$source" "$target"; then
        success "Linked $source → $target"
    else
        error "Failed to link $source → $target"
        return 1
    fi
}

# Symlink all dotfiles from config directory
link_dotfiles() {
    local config_dir="$1"
    local failures=0

    if [[ ! -d "$config_dir" ]]; then
        error "Config directory not found: $config_dir"
        return 1
    fi

    log "Symlinking dotfiles from $config_dir"

    # Handle special case for nvim config - should go to ~/.config/nvim
    if [[ -d "$config_dir/nvim" ]]; then
        local nvim_source="$config_dir/nvim"
        local nvim_target="$HOME/.config/nvim"

        # Create .config directory if needed
        mkdir -p "$HOME/.config"

        if ! create_symlink "$nvim_source" "$nvim_target"; then
            ((failures++))
        fi
    fi

    # Find all files in config, excluding .git and nvim directory
    while IFS= read -r -d '' file; do
        # Get relative path from config directory
        local rel_path="${file#$config_dir/}"
        local source="$file"
        local target="$HOME/$rel_path"

        # Skip nvim directory as it's handled separately
        if [[ "$rel_path" == nvim/* ]]; then
            continue
        fi

        # Skip if it's a directory (we'll create them as needed)
        if [[ -d "$source" ]]; then
            continue
        fi

        # Handle starship.toml -> .config/starship.toml
        if [[ "$rel_path" == "starship.toml" ]]; then
            mkdir -p "$HOME/.config"
            target="$HOME/.config/starship.toml"
        fi

        if ! create_symlink "$source" "$target"; then
            ((failures++))
        fi
    done < <(find "$config_dir" -type f -not -path "*/.git/*" -not -path "*/nvim/*" -print0)

    if [[ $failures -eq 0 ]]; then
        success "All dotfiles linked successfully"
        return 0
    else
        warn "$failures files failed to link"
        return 1
    fi
}

# Remove broken symlinks pointing to dotfiles
cleanup_broken_links() {
    local config_dir="$1"

    log "Cleaning up broken symlinks..."

    find "$HOME" -maxdepth 3 -type l -not -path "$HOME/.Trash/*" 2>/dev/null | while read -r link; do
        if [[ ! -e "$link" ]]; then
            local target
            target="$(readlink "$link")"
            if [[ "$target" == "$config_dir"* ]]; then
                log "Removing broken symlink: $link"
                rm "$link"
            fi
        fi
    done
}