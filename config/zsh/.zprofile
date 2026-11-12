# /etc/zprofile (macOS path_helper) and Debian's /etc/zsh/zprofile rebuild PATH
# and push our entries behind the system ones, so add them back in front. The
# guard covers a login shell whose ZDOTDIR points at a config without our .zshenv.
(( $+functions[_dotfiles_base_path] )) && _dotfiles_base_path
