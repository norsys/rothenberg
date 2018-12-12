THIS_FILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR := $(dir $(THIS_FILE))
RESOURCES_DIR := $(THIS_DIR)resources
ROTHENBERG_EXISTS = $(wildcard .rothenberg)

include $(RESOURCES_DIR)/env/utils.mk

PHP_BIN ?= bin/php
GIT_BIN ?= $(call locate-binary,git)
COMPOSER_BIN ?= bin/composer
COMPOSER_JSON_PATH ?= /src/composer.json

ifneq ("$(ROTHENBERG_EXISTS)","")
include $(ROTHENBERG_EXISTS)
endif

TARGET ?= app
SYMFONY_VERSION ?= "^3.4"

ifeq ($(filter $(TARGET),app bundle),)
$(error Target $(TARGET) is invalid!);
endif

.SILENT:

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: composer.json

# Implicit rules

env/%: $(RESOURCES_DIR)/env/% | env
	$(CP) $< $@

env/bin/%: $(RESOURCES_DIR)/env/bin/% | env/bin
	$(CP) $< $@

env/nginx/%: $(RESOURCES_DIR)/env/nginx/% | env/nginx
	$(CP) $< $@

src/AppBundle/Resources/config/%: | src/AppBundle/Resources/config
	$(CP) $(RESOURCES_DIR)/$@ $@

src/AppBundle/%: | src/AppBundle
	$(CP) $(RESOURCES_DIR)/$@ $@

app/config/%: | app/config
	$(CP) $(RESOURCES_DIR)/$@ $@

app/%: | app
	$(CP) $(RESOURCES_DIR)/$@ $@

web/%: | web
	$(CP) $(RESOURCES_DIR)/$@ $@

src/%: | src
	$(CP) $(RESOURCES_DIR)/$@ $@

tests/units/%: $(RESOURCES_DIR)/tests/units/% | tests/units
	$(CP) $< $@

env/php/%.ini: | env/php
	$(CP) $(RESOURCES_DIR)/$@ $@

.gitignore: $(RESOURCES_DIR)/git/ignore.$(TARGET)
	$(call merge-file,$@,$<)

.git%: $(RESOURCES_DIR)/git/%
	$(call merge-file,$@,$<)

bin/%: env/Makefile
	$(MAKE) -f $< $@

%: $(RESOURCES_DIR)/%
	$(CP) $< $@

gc/%:
	$(RM) $(patsubst gc/%,%,$@)

env env/bin env/nginx app src web tests/units env/php app/config src/AppBundle src/AppBundle/Resources/config:
	$(MKDIR) $@

# Install

.PHONY: install
install: $(THIS_FILE) Makefile install/docker install/php install/symfony install/tests install/git install/check-style install/node gc
	echo "TARGET = $(TARGET)" > .rothenberg
ifneq ("$(ROTHENBERG_EXISTS)","")
	@printf "\n=> Norsys/rothenberg update done!\n"
else
	@printf "\n=> Norsys/rothenberg installation done!\n"
endif

## Make

Makefile: | env/Makefile
	$(CP) $(RESOURCES_DIR)/$@.$(TARGET) $@

env/Makefile: $(RESOURCES_DIR)/env/$(TARGET).mk env/common.mk
	$(CP) $< $@

env/common.mk: env/utils.mk

## Tests

.PHONY: install/tests
install/tests: install/tests/units

ifeq ($(TARGET),app)
install/tests: install/tests/functionals
endif

.PHONY: install/tests/units
install/tests/units: install/symfony .atoum.php tests/units/runner.php tests/units/Test.php tests/units/src/.gitkeep

.PHONY: install/tests/functionals
install/tests/functionals: install/symfony/app behat.yml

%/.gitkeep:
	$(MKDIR) $(dir $@)
	> $@

.atoum.php behat.yml:
	$(CP) $(RESOURCES_DIR)/$@ $@

## Check-style

.PHONY: install/check-style
install/check-style: check-style.xml

check-style.xml:
	$(CP) $(RESOURCES_DIR)/$@ $@

## Docker

.PHONY: install/docker
install/docker: docker-compose.yml docker-compose.override.yml env/.env.dist env/bin/docker-compose

docker-compose.yml: $(RESOURCES_DIR)/docker-compose.$(TARGET).yml
	$(CP) $< $@

docker-compose.override.yml:
	$(CP) $(RESOURCES_DIR)/$@ $@

env/.env.dist: $(RESOURCES_DIR)/env/.env.$(TARGET).dist | env
	$(CP) $< $@

ifeq ($(TARGET),app)
env/bin/docker-compose: env/nginx/default.conf env/docker-compose.rothenberg.yml
endif

## Symfony

.PHONY: install/symfony
install/symfony: install/php composer.json | src

.PHONY: install/symfony/app
install/symfony/app: app/console.php web/app.php web/apple-touch-icon.png web/favicon.ico web/robots.txt

composer.json: $(RESOURCES_DIR)/composer.json.php | $(PHP_BIN) $(COMPOSER_BIN)
	$(PHP_BIN) -d memory_limit=-1 -f $(RESOURCES_DIR)/composer.json.php -- $(COMPOSER_JSON_PATH) $(TARGET) $(SYMFONY_VERSION)
	export GIT_SSH_COMMAND="ssh -i $(SSH_KEY) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" && $(PHP_BIN) -d memory_limit=-1 $(COMPOSER_BIN) update --lock --no-scripts --ignore-platform-reqs --no-suggest

ifeq ($(TARGET),app)
composer.json: app/console.php
endif

app/console.php: | $(RESOURCES_DIR)/app/console.php app/AppKernel.php app/autoload.php app/AppCache.php
	$(CP) $(RESOURCES_DIR)/$@ $@

app/AppKernel.php: | app/config/config.yml app/config/config_dev.yml app/config/config_prod.yml app/config/parameters.yml app/config/routing.yml app/config/routing_dev.yml app/config/security.yml src/AppBundle/AppBundle.php
	$(CP) $(RESOURCES_DIR)/$@ $@

src/AppBundle/AppBundle.php: | src/AppBundle/Resources/config/routing.yml
	$(CP) $(RESOURCES_DIR)/$@ $@

## Git

.PHONY: install/git
install/git: .git .gitattributes .gitignore env/bin/pre-commit

.git:
	$(GIT_BIN) init

## PHP

.PHONY: install/php
install/php: install/docker install/php/composer install/php/cli

ifeq ($(TARGET),app)
install/php: install/php/fpm
endif

.PHONY: install/php/cli
install/php/cli: env/php/cli.ini env/bin/bin.tpl env/bin/php

.PHONY: install/php/fpm
install/php/fpm: env/php/fpm.ini

.PHONY: install/php/composer
install/php/composer: env/bin/composer

env/bin/composer: env/bin/docker-compose

## Node

.PHONY: install/node
install/node:

ifeq ($(TARGET),app)
env/bin/docker-compose: env/bin/node env/bin/npm
endif

# GC

.PHONY: gc
gc: gc/env/php/cli gc/env/php/fpm gc/env/docker gc/env/.rothenberg
