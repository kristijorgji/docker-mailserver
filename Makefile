ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: help ress lint lint-markdown fix-markdown verify-hooks dev-init

ML_VERSION = latest

help:
	@echo "Targets:"
	@echo "  dev-init        Bootstrap repo for local development"
	@echo "  verify-hooks    Verify git pre-commit hooks are installed"
	@echo "  ress            Rebuild and restart dev stack (interactive shell)"
	@echo "  lint            Run markdown lint"
	@echo "  lint-markdown   Lint all *.md files"
	@echo "  fix-markdown    Prettier + markdownlint --fix on **/*.md"

dev-init:
	@bash scripts/dev-init.sh

verify-hooks:
	@./scripts/check-hooks.sh

ress:
	docker-compose restart && docker-compose up -d --build && docker-compose exec ms /bin/bash

lint: lint-markdown

lint-markdown:
	@echo "################################################################################"
	@echo "# markdownlint-cli2"
	@echo "################################################################################"
	@docker run --rm -v $(PWD):/data -w /data davidanson/markdownlint-cli2:$(ML_VERSION) "**/*.md"

fix-markdown:
	@echo "################################################################################"
	@echo "# Prettier (Restricted to Markdown)"
	@echo "################################################################################"
	@docker run --rm \
		-v $(PWD):/work \
		-w /work \
		--user $$(id -u):$$(id -g) \
		tmknom/prettier:latest \
		--write "**/*.md" \
		--parser markdown \
		--ignore-path .gitignore
	@echo "################################################################################"
	@echo "# markdownlint-cli2 --fix"
	@echo "################################################################################"
	@docker run --rm -v $(PWD):/data -w /data davidanson/markdownlint-cli2:$(ML_VERSION) --fix "**/*.md"
