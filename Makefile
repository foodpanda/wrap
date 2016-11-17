.PHONY: help
help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-10s\033[0m - %s\n", $$1, $$2}'
	@echo

.PHONY: lint
lint: ## perform lint check
	shellcheck wrap.sh
