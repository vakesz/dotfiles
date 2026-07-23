# Python virtualenv helpers

_dotfiles_sha256() {
  local digest

  if (( $+commands[shasum] )); then
    digest="$(command shasum -a 256)" || return 1
  elif (( $+commands[sha256sum] )); then
    digest="$(command sha256sum)" || return 1
  else
    return 1
  fi

  print -r -- "${digest%% *}"
}

_dotfiles_venv_trust_record() {
  local project_dir="${1:A}"
  local project_hash

  project_hash="$(print -rn -- "$project_dir" | _dotfiles_sha256)" || return 1
  print -r -- "$XDG_STATE_HOME/zsh/trusted-venvs/$project_hash"
}

_dotfiles_venv_activate_hash() {
  local activate_file="$1"
  _dotfiles_sha256 < "$activate_file"
}

_dotfiles_venv_is_trusted() {
  local project_dir="${1:A}"
  local activate_file="$project_dir/.venv/bin/activate"
  local trust_record trusted_hash activate_hash

  trust_record="$(_dotfiles_venv_trust_record "$project_dir")" || return 1
  [[ -r "$trust_record" ]] || return 1

  trusted_hash="$(<"$trust_record")"
  activate_hash="$(_dotfiles_venv_activate_hash "$activate_file")" || return 1
  [[ -n "$trusted_hash" && "$trusted_hash" == "$activate_hash" ]]
}

venv-trust() {
  local project_dir="${PWD:A}"
  local activate_file="$project_dir/.venv/bin/activate"
  local trust_record activate_hash temporary_record

  if [[ ! -f "$activate_file" ]]; then
    print -u2 -r -- "Error: no .venv/bin/activate found in $project_dir"
    return 1
  fi

  trust_record="$(_dotfiles_venv_trust_record "$project_dir")" || {
    print -u2 -r -- "Error: SHA-256 support requires shasum or sha256sum"
    return 1
  }
  activate_hash="$(_dotfiles_venv_activate_hash "$activate_file")" || {
    print -u2 -r -- "Error: unable to fingerprint $activate_file"
    return 1
  }

  command mkdir -p -- "${trust_record:h}" || return 1
  command chmod 700 -- "${trust_record:h}" || return 1
  temporary_record="${trust_record}.$$"

  if ! (umask 077; print -r -- "$activate_hash" >| "$temporary_record"); then
    command rm -f -- "$temporary_record"
    return 1
  fi
  command mv -f -- "$temporary_record" "$trust_record" || {
    command rm -f -- "$temporary_record"
    return 1
  }

  print -r -- "Trusted virtualenv: $project_dir/.venv"
  _dotfiles_auto_venv
}

venv-untrust() {
  local project_dir="${PWD:A}"
  local trust_record

  trust_record="$(_dotfiles_venv_trust_record "$project_dir")" || {
    print -u2 -r -- "Error: SHA-256 support requires shasum or sha256sum"
    return 1
  }
  command rm -f -- "$trust_record" || return 1

  if [[ -n "$VIRTUAL_ENV" && "${VIRTUAL_ENV:A}" == "$project_dir/.venv" ]]; then
    (( $+functions[deactivate] )) && deactivate
  fi

  print -r -- "Removed virtualenv trust: $project_dir/.venv"
}

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
    if _dotfiles_venv_is_trusted "$PWD"; then
      source ".venv/bin/activate"
    else
      print -r -- "Virtualenv is not trusted: ${PWD:A}/.venv"
      print -r -- "Review .venv/bin/activate, then run: venv-trust"
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dotfiles_auto_venv
_dotfiles_auto_venv
