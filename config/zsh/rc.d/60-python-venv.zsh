# Python virtualenv helpers

venv() {
  local venv_dir="${1:-.venv}"

  if [[ -f "$venv_dir/bin/activate" ]]; then
    source "$venv_dir/bin/activate"
    return
  fi

  if [[ -d "$venv_dir" ]]; then
    echo "Error: $venv_dir exists but is not a valid virtualenv" >&2
    return 1
  fi

  (( $+commands[uv] )) || {
    echo "Error: uv not found" >&2
    return 1
  }

  echo "Creating virtualenv with uv in $venv_dir..."
  uv venv "$venv_dir" && source "$venv_dir/bin/activate"
}

venv-off() {
  (( $+functions[deactivate] )) && deactivate
}
alias venv-deactivate='venv-off'

_dotfiles_auto_venv() {
  # Recover from a venv whose directory was deleted while still "active".
  if [[ -n "$VIRTUAL_ENV" && ! -f "$VIRTUAL_ENV/bin/activate" ]]; then
    if (( $+functions[deactivate] )); then
      deactivate
    else
      unset VIRTUAL_ENV
    fi
  fi

  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_parent="${VIRTUAL_ENV:h}"
    if [[ "$PWD" != "${venv_parent}/"* && "$PWD" != "$venv_parent" ]]; then
      (( $+functions[deactivate] )) && deactivate
    fi
  fi

  if [[ -z "$VIRTUAL_ENV" && -f ".venv/bin/activate" ]]; then
    source ".venv/bin/activate"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dotfiles_auto_venv
_dotfiles_auto_venv
