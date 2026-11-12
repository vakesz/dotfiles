# Python virtualenv helpers. Per-project auto-activation goes through direnv
# (hooked in 40-tools.zsh), whose `direnv allow` is the trust check: a changed
# .envrc stays blocked until it is allowed again.

# Activate a virtualenv for this shell, creating it with uv if it's missing.
venv() {
  local venv_dir="${1:-.venv}"

  if [[ -f "$venv_dir/bin/activate" ]]; then
    source "$venv_dir/bin/activate"
    return
  fi

  if [[ -d "$venv_dir" ]]; then
    print -u2 -r -- "Error: $venv_dir exists but is not a valid virtualenv"
    return 1
  fi

  (( $+commands[uv] )) || {
    print -u2 -r -- "Error: uv not found"
    return 1
  }

  echo "Creating virtualenv with uv in $venv_dir..."
  uv venv "$venv_dir" && source "$venv_dir/bin/activate"
}

# Make direnv activate a virtualenv whenever the shell is in this directory.
# Only setting VIRTUAL_ENV and PATH carries over: direnv exports variables, so
# the functions and prompt changes in bin/activate would be lost anyway.
venv-auto() {
  local venv_dir="${1:-.venv}"
  local envrc="$PWD/.envrc"
  local -a lines=(
    "export VIRTUAL_ENV=\"\$(expand_path ${(qq)venv_dir})\""
    'PATH_add "$VIRTUAL_ENV/bin"'
  )

  (( $+commands[direnv] )) || {
    print -u2 -r -- "Error: direnv not found"
    return 1
  }

  if [[ ! -f "$venv_dir/bin/activate" ]]; then
    if [[ -d "$venv_dir" ]]; then
      print -u2 -r -- "Error: $venv_dir exists but is not a valid virtualenv"
      return 1
    fi
    (( $+commands[uv] )) || {
      print -u2 -r -- "Error: uv not found"
      return 1
    }
    uv venv "$venv_dir" || return
  fi

  # Never edit an existing .envrc: it may do more than this, and allowing it
  # unread would skip the review direnv's trust check exists for.
  if [[ -e "$envrc" ]]; then
    print -u2 -r -- "$envrc already exists. Add these lines, then run: direnv allow"
    print -u2 -rl -- "${lines[@]}"
    return 1
  fi

  # A manually activated venv would fight direnv over PATH.
  (( $+functions[deactivate] )) && deactivate
  print -rl -- "# Activate the project virtualenv (written by venv-auto)." "${lines[@]}" >| "$envrc" || return
  print -r -- "Wrote $envrc"
  direnv allow "$envrc"
}

venv-off() {
  if (( $+functions[deactivate] )); then
    deactivate
  elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
    print -u2 -r -- "This virtualenv comes from direnv. Leave the directory or run: direnv deny"
    return 1
  fi
}
alias venv-deactivate='venv-off'
