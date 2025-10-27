#!/usr/bin/env bash

# File permissions security utilities

# shellcheck source=lib/platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

set_secure_permissions() {
    local config_dir="$1"

    log "Setting secure permissions on configuration files..."

    # Sensitive files should be 600 (owner read/write only)
    local sensitive_files=(
        ".gitconfig"
        ".gitconfig.platform"
        ".zshrc"
        ".bashrc"
        ".profile"
        ".tmux.conf"
        ".zsh_history"
        ".bash_history"
    )

    local changed=0

    for file in "${sensitive_files[@]}"; do
        local target="$HOME/$file"
        if [[ -f "$target" || -L "$target" ]]; then
            # Skip broken symlinks
            if [[ -L "$target" ]] && ! readlink -e "$target" >/dev/null 2>&1; then
                warn "Skipping broken symlink: $file"
                continue
            fi
            
            # Get current permissions
            local current_perms
            if is_macos; then
                current_perms=$(stat -f "%A" "$target" 2>/dev/null || echo "000")
            else
                current_perms=$(stat -c "%a" "$target" 2>/dev/null || echo "000")
            fi

            # Set to 600 if not already set
            if [[ "$current_perms" != "600" ]]; then
                if chmod 600 "$target" 2>/dev/null; then
                    log "Set permissions 600 on $file (was $current_perms)"
                    ((changed++))
                else
                    warn "Failed to set permissions on $file"
                fi
            fi
        fi
    done

    # SSH configuration must be properly secured
    if [[ -d "$HOME/.ssh" ]]; then
        # SSH directory should be 700
        local ssh_dir_perms
        if is_macos; then
            ssh_dir_perms=$(stat -f "%A" "$HOME/.ssh" 2>/dev/null || echo "000")
        else
            ssh_dir_perms=$(stat -c "%a" "$HOME/.ssh" 2>/dev/null || echo "000")
        fi

        if [[ "$ssh_dir_perms" != "700" ]]; then
            if chmod 700 "$HOME/.ssh"; then
                log "Set permissions 700 on .ssh directory (was $ssh_dir_perms)"
                ((changed++))
            fi
        fi

        # SSH config file should be 600
        if [[ -f "$HOME/.ssh/config" ]]; then
            chmod 600 "$HOME/.ssh/config" 2>/dev/null && log "Set permissions 600 on .ssh/config"
        fi

        # Private keys must be 600
        local key_files_found=0
        while IFS= read -r -d '' key_file; do
            chmod 600 "$key_file" 2>/dev/null && ((key_files_found++))
        done < <(find "$HOME/.ssh" -type f \( -name "id_*" -o -name "*_rsa" -o -name "*_ed25519" -o -name "*_ecdsa" \) -not -name "*.pub" -print0 2>/dev/null)

        if [[ $key_files_found -gt 0 ]]; then
            log "Set permissions 600 on $key_files_found SSH private key(s)"
            ((changed++))
        fi

        # Public keys should be 644
        while IFS= read -r -d '' pub_key; do
            chmod 644 "$pub_key" 2>/dev/null
        done < <(find "$HOME/.ssh" -type f -name "*.pub" -print0 2>/dev/null)
    fi

    # Neovim config directory permissions
    if [[ -d "$HOME/.config/nvim" ]]; then
        chmod 755 "$HOME/.config/nvim" 2>/dev/null || true
    fi

    # Prevent world-writable files in home directory
    local world_writable_count=0
    while IFS= read -r -d '' file; do
        if chmod go-w "$file" 2>/dev/null; then
            warn "Removed world-writable permission from: $(basename "$file")"
            ((world_writable_count++))
        fi
    done < <(find "$HOME" -maxdepth 1 -type f -perm -o+w -print0 2>/dev/null)

    if [[ $world_writable_count -gt 0 ]]; then
        ((changed += world_writable_count))
    fi

    if [[ $changed -gt 0 ]]; then
        success "Secured $changed file(s) with proper permissions"
    else
        success "All file permissions are already secure"
    fi
}

verify_permissions() {
    log "Verifying file permissions..."

    local issues=0

    # Check critical files
    local critical_files=(
        "$HOME/.gitconfig"
        "$HOME/.zshrc"
        "$HOME/.ssh/config"
    )

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" || -L "$file" ]]; then
            local perms
            if is_macos; then
                perms=$(stat -f "%A" "$file" 2>/dev/null || echo "000")
            else
                perms=$(stat -c "%a" "$file" 2>/dev/null || echo "000")
            fi

            # Check if too permissive (group or other can write)
            if [[ "${perms:1:1}" != "0" ]] || [[ "${perms:2:1}" != "0" ]]; then
                error "Insecure permissions on $file: $perms (should be 600)"
                ((issues++))
            fi
        fi
    done

    # Check for world-writable files in home
    local world_writable
    world_writable=$(find "$HOME" -maxdepth 1 -type f -perm -o+w 2>/dev/null | wc -l)

    if [[ $world_writable -gt 0 ]]; then
        warn "$world_writable world-writable file(s) found in home directory"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        success "All file permissions verified secure"
        return 0
    else
        error "$issues permission issue(s) found"
        return 1
    fi
}
