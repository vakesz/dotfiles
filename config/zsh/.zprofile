# Login shell setup

# /etc/zprofile (path_helper) and Debian's /etc/zsh/zprofile rebuild PATH and push
# our entries behind the system ones. Guarded because a nested login shell inherits
# ZDOTDIR, so zsh reads $ZDOTDIR/.zshenv and never sees ~/.zshenv.
(( $+functions[_dotfiles_base_path] )) && _dotfiles_base_path
export PATH
