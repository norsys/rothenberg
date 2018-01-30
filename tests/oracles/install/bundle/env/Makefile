include env/common.mk

# Install

.PHONY: install
install: docker/pull .install docker/clean ## Install application.

.install: vendor/autoload.php tmp
	echo "ENV ?= $(ENV)" > $@
	echo "SYMFONY_ENV ?= $(SYMFONY_ENV)" >> $@
	echo "SSH_KEY ?= $(SSH_KEY)" >> $@

tmp:
	$(MKDIR) tmp

## Docker

bin/docker-compose: | bin/. .env
	$(call install,$@)

.env: env/.env.dist $(SSH_KEY) | $(COMPOSER_CACHE)
	export ETC=$(ETC) USER_HOME=$(HOME) USER_ID=$(USER_ID) SYMFONY_ENV=$(SYMFONY_ENV) SSH_KEY=$(SSH_KEY) COMPOSER_CACHE=$(COMPOSER_CACHE) ENV=$(ENV) SYMFONY_DEBUG=$(SYMFONY_DEBUG) && $(call export-file,$<,$@)
