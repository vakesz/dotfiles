SHELL := /usr/bin/env bash

SHELL_SCRIPTS := bootstrap.sh install.sh $(wildcard scripts/*.sh) $(wildcard scripts/lib/*.sh) $(wildcard scripts/platform/*.sh)
ZSH_SCRIPTS := home/.zshenv config/zsh/.zprofile config/zsh/.zshrc $(wildcard config/zsh/rc.d/*.zsh)
JSON_FILES := config/linearmouse/linearmouse.json
TOML_FILES := config/starship.toml config/tealdeer/config.toml config/topgrade.toml

.DEFAULT_GOAL := help
.PHONY: help install bootstrap adopt macos linux doctor check lint zsh-check config-check brew-check brew-install

help: ## Show this help
	@printf 'Targets:\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk -F':.*?## ' '{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

install: ## Run the one-line installer (clone + bootstrap) on a fresh machine
	@./install.sh

bootstrap: ## Run the full bootstrap (preflight, stow, platform setup)
	@./bootstrap.sh

adopt: ## Bootstrap and import existing dotfiles into the repo
	@./bootstrap.sh --adopt

macos: ## Run the macOS platform setup on its own
	@./scripts/platform/macos.sh

linux: ## Run the Linux / WSL platform setup on its own
	@./scripts/platform/linux.sh

doctor: ## Verify the machine matches what bootstrap should have produced
	@./scripts/doctor.sh

check: lint zsh-check config-check ## Run every repository validation

lint: ## Shellcheck every bash script in the repo
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed: brew install shellcheck"; exit 1; }
	@shellcheck --shell=bash --external-sources $(SHELL_SCRIPTS)
	@echo "shellcheck: clean"

zsh-check: ## Parse every Zsh configuration file
	@command -v zsh >/dev/null 2>&1 || { echo "zsh not installed"; exit 1; }
	@for file in $(ZSH_SCRIPTS); do zsh -n "$$file"; done
	@echo "zsh syntax: clean"

config-check: ## Parse structured configuration and check whitespace
	@command -v jq >/dev/null 2>&1 || { echo "jq not installed"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "python3 not installed"; exit 1; }
	@command -v ruby >/dev/null 2>&1 || { echo "ruby not installed"; exit 1; }
	@jq empty $(JSON_FILES)
	@python3 -c 'import sys, tomllib; [tomllib.load(open(path, "rb")) for path in sys.argv[1:]]' $(TOML_FILES)
	@git config --file config/git/config --list >/dev/null
	@ruby -c Brewfile >/dev/null
	@diff -u <(grep -vE '^(#|$$)' config/fd/ignore) <(sed -n 's/^--glob=!\(.*\)$$/\1/p' config/ripgrep/config)
	@duplicates=$$(sed -nE 's/^(brew|cask) "([^"]+)".*/\2/p' Brewfile | sort | uniq -d); \
		test -z "$$duplicates" || { printf 'duplicate Brewfile entries:\n%s\n' "$$duplicates"; exit 1; }
	@git diff --check HEAD
	@echo "config syntax and whitespace: clean"

brew-check: ## Report Brewfile entries that are not installed
	@brew bundle check --file Brewfile --verbose

brew-install: ## Install everything declared in the Brewfile
	@brew bundle install --file Brewfile
