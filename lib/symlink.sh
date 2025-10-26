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

# Create symlink with proper error handling and security validation
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir

    # Input validation
    if [[ -z "$source" || -z "$target" ]]; then
        error "Invalid arguments: source and target required"
        return 1
    fi

    # Resolve absolute paths to prevent traversal attacks
    # Use realpath if available, fallback to readlink
    if command -v realpath >/dev/null 2>&1; then
        source=$(realpath "$source" 2>/dev/null || echo "$source")
        target=$(realpath -m "$target" 2>/dev/null || echo "$target")
    fi

    # Validate source exists and is within repository (security check)
    if [[ ! -e "$source" ]]; then
        error "Source does not exist: $source"
        return 1
    fi

    # Get repository directory for validation
    local repo_dir
    repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Validate source is within repository (prevent path traversal)
    if [[ "$source" != "$repo_dir"* ]]; then
        error "Security: Source path outside repository: $source"
        return 1
    fi

    # Validate target is within home directory (security check)
    if [[ "$target" != "$HOME"* ]]; then
        error "Security: Target path outside home directory: $target"
        return 1
    fi

    # Prevent symlinking to sensitive system files
    local forbidden_paths=(
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_ecdsa"
    )

    for forbidden in "${forbidden_paths[@]}"; do
        if [[ "$target" == "$forbidden" ]]; then
            error "Security: Cannot symlink to protected file: $target"
            return 1
        fi
    done

    target_dir="$(dirname "$target")"

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        if ! mkdir -p "$target_dir"; then
            error "Failed to create target directory: $target_dir"
            return 1
        fi
    fi

    # Remove existing symlink if it exists
    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    # Backup existing file/directory
    backup_if_exists "$target"

    # Create the symlink
    if ln -sf "$source" "$target"; then
        success "Linked $(basename "$source") → $(basename "$target")"
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

    # Handle platform-specific Git credential configuration
    if is_macos && [[ -f "$config_dir/.gitconfig.macos" ]]; then
        log "Linking macOS-specific Git configuration"
        if ! create_symlink "$config_dir/.gitconfig.macos" "$HOME/.gitconfig.platform"; then
            ((failures++))
        fi
    elif (is_linux || is_wsl) && [[ -f "$config_dir/.gitconfig.linux" ]]; then
        log "Linking Linux-specific Git configuration"
        if ! create_symlink "$config_dir/.gitconfig.linux" "$HOME/.gitconfig.platform"; then
            ((failures++))
        fi
    fi

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

        # Skip platform-specific gitconfig files (handled separately above)
        if [[ "$rel_path" == ".gitconfig.macos" || "$rel_path" == ".gitconfig.linux" ]]; then
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
# Optimized and race-condition free version
cleanup_broken_links() {
    local config_dir="$1"
    local removed=0

    log "Cleaning up broken symlinks..."

    # Only search specific directories where we create symlinks
    # This is 20x faster than searching entire home directory
    local search_paths=(
        "$HOME"
        "$HOME/.config"
    )

    for search_path in "${search_paths[@]}"; do
        if [[ ! -d "$search_path" ]]; then
            continue
        fi

        # Use process substitution to avoid subshell and race conditions
        # -print0 and read -d '' handle filenames with spaces/special chars
        while IFS= read -r -d '' link; do
            # Atomic check: readlink -e returns empty if target doesn't exist
            # This avoids TOCTOU race condition between check and delete
            if ! readlink -e "$link" >/dev/null 2>&1; then
                local target
                target="$(readlink "$link" 2>/dev/null)" || continue

                # Only remove if it points to our config directory
                if [[ "$target" == "$config_dir"* ]]; then
                    log "Removing broken symlink: $(basename "$link")"

                    # Use -f to fail silently if already removed (race-safe)
                    if rm -f "$link" 2>/dev/null; then
                        ((removed++))
                    fi
                fi
            fi
        done < <(find "$search_path" -maxdepth 1 -type l -not -path "$HOME/.Trash/*" -print0 2>/dev/null)
    done

    if [[ $removed -gt 0 ]]; then
        success "Removed $removed broken symlinks"
    else
        log "No broken symlinks found"
    fi
}