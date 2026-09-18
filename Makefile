SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help
.PHONY: help bootstrap adopt macos linux doctor check check-shell check-fmt check-zsh check-config check-apps brew-check brew-install

help: ## Show this help
	@printf 'Targets:\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk -F':.*?## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

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

check: check-shell check-fmt check-zsh check-config ## Run every repository validation

check-shell: ## Shellcheck every bash script in the repo
	@./scripts/check.sh shell

check-fmt: ## Check bash script formatting with shfmt
	@./scripts/check.sh fmt

check-zsh: ## Parse every Zsh configuration file
	@./scripts/check.sh zsh

check-config: ## Parse structured configuration and check whitespace
	@./scripts/check.sh config

check-apps: ## Ask installed applications to validate their configuration
	@./scripts/check-apps.sh

brew-check: ## Report Brewfile entries that are not installed
	@brew bundle check --file Brewfile --verbose

brew-install: ## Install everything declared in the Brewfile
	@brew bundle install --file Brewfile
