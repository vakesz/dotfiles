# Python virtualenv helpers. Auto-activation is gated on trust because
# .venv/bin/activate is arbitrary project-supplied shell code.

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

_dotfiles_venv_record() {
  local project_hash

  project_hash="$(print -rn -- "${1:A}" | _dotfiles_sha256)" || return 1
  print -r -- "$XDG_STATE_HOME/zsh/trusted-venvs/$project_hash"
}

_dotfiles_venv_trusted() {
  local record want have

  record="$(_dotfiles_venv_record "$1")" || return 1
  [[ -r "$record" ]] || return 1

  want="$(<"$record")"
  have="$(_dotfiles_sha256 < "${1:A}/.venv/bin/activate")" || return 1
  # Without -n an empty record would match an empty hash and auto-activate.
  [[ -n "$want" && "$want" == "$have" ]]
}

venv-trust() {
  local project_dir="${PWD:A}"
  local activate_file="$project_dir/.venv/bin/activate"
  local record hash

  if [[ ! -f "$activate_file" ]]; then
    print -u2 -r -- "Error: no .venv/bin/activate found in $project_dir"
    return 1
  fi

  record="$(_dotfiles_venv_record "$project_dir")" || {
    print -u2 -r -- "Error: SHA-256 support requires shasum or sha256sum"
    return 1
  }
  hash="$(_dotfiles_sha256 < "$activate_file")" || {
    print -u2 -r -- "Error: unable to fingerprint $activate_file"
    return 1
  }

  # chmod because mkdir -m does not tighten an existing 0755 directory.
  command mkdir -p -- "${record:h}" && command chmod 700 -- "${record:h}" || return 1
  (umask 077; print -r -- "$hash" >| "$record") || return 1

  print -r -- "Trusted virtualenv: $project_dir/.venv"
  _dotfiles_venv_auto
}

venv-untrust() {
  local project_dir="${PWD:A}"
  local record

  record="$(_dotfiles_venv_record "$project_dir")" || {
    print -u2 -r -- "Error: SHA-256 support requires shasum or sha256sum"
    return 1
  }
  command rm -f -- "$record" || return 1

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

_dotfiles_venv_auto() {
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
    if _dotfiles_venv_trusted "$PWD"; then
      source ".venv/bin/activate"
    else
      print -r -- "Virtualenv is not trusted: ${PWD:A}/.venv"
      print -r -- "Review .venv/bin/activate, then run: venv-trust"
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dotfiles_venv_auto
_dotfiles_venv_auto
