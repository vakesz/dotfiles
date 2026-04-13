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

  command_exists uv || {
    echo "Error: uv not found" >&2
    return 1
  }

  echo "Creating virtualenv with uv in $venv_dir..."
  uv venv "$venv_dir" && source "$venv_dir/bin/activate"
}

alias venv-off='deactivate'

auto_activate_venv() {
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
add-zsh-hook chpwd auto_activate_venv
auto_activate_venv
