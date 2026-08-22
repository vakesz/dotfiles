SHELL := /usr/bin/env bash

SHELL_SCRIPTS := bootstrap.sh install.sh $(wildcard scripts/*.sh) $(wildcard scripts/lib/*.sh) $(wildcard scripts/platform/*.sh)

.DEFAULT_GOAL := help
.PHONY: help install bootstrap adopt macos linux doctor lint brew-check brew-install

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

lint: ## Shellcheck every bash script in the repo
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed: brew install shellcheck"; exit 1; }
	@shellcheck --shell=bash --external-sources $(SHELL_SCRIPTS)
	@echo "shellcheck: clean"

brew-check: ## Report Brewfile entries that are not installed
	@brew bundle check --file Brewfile --verbose

brew-install: ## Install everything declared in the Brewfile
	@brew bundle install --file Brewfile
