.PHONY: help
help:
	@ echo "Please use \`make <target>' where <target> is one of"
	@ echo
	@ grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-10s\033[0m - %s\n", $$1, $$2}'
	@ echo

check-shellcheck:
	@ hash shellcheck 2>/dev/null || { echo "Please install 'shellcheck' first"; exit 1; }

.PHONY: lint
lint: check-shellcheck ## perform lint checks
	@ find . -name "*.sh" -printf "Checking %P ...\n" -exec shellcheck {} \;

.PHONY: install
install: PREFIX ?= /usr/local/bin
install: ## install wrap into PREFIX
	if [ -L "$(PREFIX)/wrap" ]; then rm -f "$(PREFIX)/wrap"; fi
	mkdir -p "$(PREFIX)"
	cp -f wrap.sh "$(PREFIX)/wrap"
	@ echo "Installed as $(PREFIX)/wrap"
