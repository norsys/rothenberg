# http://www.davidrothenberg.net

THIS_FILE := $(lastword $(MAKEFILE_LIST))

-include .rothenberg

include env/utils.mk

ifneq ("$(wildcard .install)","")
include .install
endif

-include .rothenberg.config

ENVS ?= dev prod

ENV ?= $(shell if [ -d ./.git ]; then printf 'dev'; else printf 'prod'; fi)

ifeq ($(filter $(ENV),$(ENVS)),)
$(error ENV $(ENV) is invalid!);
endif

SYMFONY_ENVS ?= $(ENVS)

SYMFONY_ENV ?= $(ENV)
SYMFONY_DEBUG ?= true

ifeq ($(filter $(SYMFONY_ENV),$(ENVS)),)
$(error SYMFONY_ENV $(SYMFONY_ENV) is invalid!);
endif

COMPOSER_CACHE ?= $(HOME)/.composer/cache
COMPOSER_OPTIONS := --no-suggest

ifeq ($(ENV),dev)
COMPOSER_OPTIONS += --prefer-dist
endif

ifeq ($(SYMFONY_ENV),prod)
COMPOSER_OPTIONS += -o --no-dev
endif

WITH_DOCKER_PULL ?= yes

DOCKER_BIN ?= $(call locate-binary,docker)

DOCKER_COMPOSE_IMAGE ?= docker/compose
DOCKER_COMPOSE_VERSION ?= 1.11.2

ROTHENBERG_NETWORK ?= rothenberg

USER_ID = $(shell id -u)
SSH_KEY ?= $(HOME)/.ssh/id_rsa

ifeq ($(shell uname -s),Darwin)
OS = osx
else
OS = linux
endif

export

.SILENT:

.SUFFIXES:

.DELETE_ON_ERROR:

## Implicit rules

.PRECIOUS: %/.
%/.:
	$(MKDIR) $@

# prevents conflict between %/. and bin/% for bin/.
.PRECIOUS: bin/.
bin/.:
	$(MKDIR) bin

bin/%: env/bin/% | bin/docker-compose
	$(call install,$@)

.PHONY: uninstall/%
uninstall/%:
	$(call uninstall,$@)

## Rothenberg

.PHONY: rothenberg/update
rothenberg/update:  TARGET ?= $(error Please install rothenberg before update it!`)
rothenberg/update: | bin/composer
	bin/composer update --no-suggest --no-scripts --ignore-platform-reqs norsys/rothenberg
	$(MAKE) -f vendor/norsys/rothenberg/install.mk install # Can not be made via composer, because composer is running in a docker, so docker is unavailable and some post-(?:install|update) command not works

.PHONY: rothenberg/targets
rothenberg/targets:
	@$(MAKE) -pRrq -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: rothenberg/docker/services
rothenberg/docker/services: bin/docker-compose
	bin/docker-compose -f docker-compose.yml config --services | grep -v hosts

.rothenberg.config:
	@echo "WITH_DOCKER_PULL ?= $(WITH_DOCKER_PULL)" > $@
	@echo "DOCKER_COMPOSE_IMAGE ?= $(DOCKER_COMPOSE_IMAGE)" >> $@
	@echo "DOCKER_COMPOSE_VERSION ?= $(DOCKER_COMPOSE_VERSION)" >> $@
	@echo "ROTHENBERG_NETWORK ?= $(ROTHENBERG_NETWORK)" >> $@

## Docker

.PHONY: docker/stop
docker/stop: | bin/docker-compose
	bin/docker-compose down --remove-orphans

.PHONY: docker/clean
docker/clean: | bin/docker-compose
	$(DOCKER_BIN) system prune -f

.PHONY: docker/pull
ifneq ($(WITH_DOCKER_PULL),yes)
docker/pull:
else
docker/pull: | bin/docker-compose
	# Add `--ignore-pull-failures` to avoid error ` pull access denied for …, repository does not exist or may require 'docker login'`, see https://github.com/docker/compose/issues/5478.
	bin/docker-compose pull --ignore-pull-failures
endif

.PHONY: docker/status
docker/status: | bin/docker-compose ## Display status of containers.
	bin/docker-compose ps

## Tests

.PHONY: unit-tests
unit-tests: bin/atoum | tests/units/src/. ## Run all unit tests.
	bin/atoum

bin/atoum: vendor/bin/atoum env/bin/bin.tpl | bin/docker-compose
	export BINARY=$< && $(call export-file,env/bin/bin.tpl,bin/atoum) && $(call executable,bin/atoum)

vendor/bin/atoum: | vendor/autoload.php

## Security

.PHONY: security
security: | bin/console ## Check security of PHP depedencies.
	bin/console security:check composer.lock --env=$(SYMFONY_ENV)

## Checker/fixer

.PHONY: check-style
check-style: check-style-php ## Check coding conventions for all languages.

.PHONY: check-style-php
check-style-php: bin/phpcs ## Check coding conventions for PHP code.
	bin/phpcs --encoding=UTF-8 --ignore=.css --ignore=.scss --ignore=.js --standard=./check-style.xml ./src

bin/phpcs: vendor/bin/phpcs env/bin/bin.tpl | bin/docker-compose
	export BINARY=vendor/squizlabs/php_codesniffer/scripts/phpcs && $(call export-file,env/bin/bin.tpl,bin/phpcs) && $(call executable,bin/phpcs)

vendor/bin/phpcs: | vendor/autoload.php

fix-style-php: bin/phpcbf ## Fix coding conventions for PHP code.
	bin/phpcbf -w --no-patch --encoding=UTF-8 --ignore=.css --ignore=.scss --ignore=.js --standard=./check-style.xml ./src

bin/phpcbf: vendor/bin/phpcbf env/bin/bin.tpl | bin/docker-compose
	export BINARY=vendor/squizlabs/php_codesniffer/scripts/phpcbf && $(call export-file,env/bin/bin.tpl,bin/phpcbf) && $(call executable,bin/phpcbf)

vendor/bin/phpcbf: | vendor/autoload.php

## Symfony

bin/console: app/console.php env/bin/bin.tpl | vendor/autoload.php bin/docker-compose
	export BINARY=app/console.php; $(call export-file,env/bin/bin.tpl,$@); $(call executable,$@)

vendor/autoload.php: composer.json env/bin/bin.tpl | bin/composer var/.
	bin/composer install $(COMPOSER_OPTIONS)
	for binary in $$(find vendor/bin -type l); do export BINARY=$$binary; $(call export-file,env/bin/bin.tpl,bin/$${binary##*/}); $(call executable,bin/$${binary##*/}); done

## Composer

bin/composer: $(THIS_FILE) | bin/docker-compose composer.passwd $(COMPOSER_CACHE)/.
	$(call install,$@)

composer.passwd:
	echo "root:x:`id -u`:0:root:/root:/bin/sh" > $@

## Git

.git/hooks/pre-commit: ./env/bin/pre-commit | .git ## Install pre-commit hook for git.
	cp ./env/bin/pre-commit .git/hooks
	$(call executable,$@)

.git:
	git init

## The help, because if no help, no RTFM

.PHONY: help
help: ## Display this help.
	@printf "$$(cat $(MAKEFILE_LIST) | egrep -h '^[^:]+:[^#]+## .+$$' | sed -e 's/:[^#]*##/:/' -e 's/\(.*\):/\\033[92m\1\\033[0m:/' | sort -d | column -c2 -t -s :)\n"

## Install

ifeq ($(ENV),dev)
install: .git/hooks/pre-commit
endif

## Uninstall

.PHONY: uninstall
uninstall: uninstall/.install ## Remove all files generated by `install`.

.PHONY: uninstall/.install
uninstall/.install: uninstall/docker uninstall/symfony uninstall/.git/hooks/pre-commit
	$(call uninstall,$@)

.PHONY: uninstall/docker
uninstall/docker: uninstall/bin/docker-compose

.PHONY: uninstall/bin/docker-compose
uninstall/bin/docker-compose: docker/clean uninstall/.env
	$(call uninstall,$@)

.PHONY: uninstall/symfony
uninstall/symfony: uninstall/bin

.PHONY: uninstall/bin
uninstall/bin: uninstall/vendor uninstall/bin/docker-compose uninstall/bin/composer
	$(call uninstall,$@)

.PHONY: uninstall/bin/composer
uninstall/bin/composer: uninstall/composer.passwd
	$(call uninstall,$@)

.PHONY: uninstall/vendor
uninstall/vendor: docker/clean
	for binary in $$(find bin -type l); do $(RM) $$binary; done
	$(call uninstall,$@)

.PHONY: reinstall
reinstall: uninstall ## Remove all installed files and reinstall the application.
	$(MAKE) install
