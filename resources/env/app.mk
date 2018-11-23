include env/common.mk

VIRTUAL_HOST ?= rothenberg.dev
ETC ?= /etc
HOSTS_ETC = /tmp/etc

NPM_CACHE ?= $(HOME)/.npm

NGINX_PROXY := bin/docker-compose -f env/docker-compose.rothenberg.yml -p $(ROTHENBERG_NETWORK) up -d || true

ifneq ("$(wildcard bin/docker-compose)","")
$(shell $(NGINX_PROXY))
endif

## Install

.PHONY: install
install: docker/pull node .install install/host docker/clean ## Install application.
	@printf "$$(cat .install | sed -e 's/:[^#]*##/?=/' -e 's/\(.*\)?=/\\033[92m\1\\033[0m:/' | column -c2 -t -s :)\n"

.PHONY: install/host
ifneq ($(OS),linux)
install/host:
else
install/host: | bin/docker-compose
	bin/docker-compose run --rm hosts bash -c "grep -q -F '127.0.0.1 $(VIRTUAL_HOST)' $(HOSTS_ETC)/hosts || echo '127.0.0.1 $(VIRTUAL_HOST)' >> $(HOSTS_ETC)/hosts"
endif

.install: | var web
	echo "ENV ?= $(ENV)" >> $@
	echo "SYMFONY_ENV ?= $(SYMFONY_ENV)" >> $@
	echo "SSH_KEY ?= $(SSH_KEY)" >> $@

web: web/bundles

web/bundles: | bin/console
	bin/console assets:install

var: var/sessions var/cache

var/%:
	$(MKDIR) $@

bin/docker-compose: | bin/. .env
	$(call install,$@)
	$(NGINX_PROXY)

$(NPM_CACHE):
	$(MKDIR) $@

$(COMPOSER_CACHE):
	$(MKDIR) $(COMPOSER_CACHE)

.env: env/.env.dist $(firstword $(MAKEFILE_LIST)) $(SSH_KEY) | $(COMPOSER_CACHE) $(NPM_CACHE)
	$(RM) var/cache
	if [ -x bin/docker-compose -a -f .env ]; then bin/docker-compose down; fi
	export ETC=$(ETC) USER_HOME=$(HOME) USER_ID=$(USER_ID) SYMFONY_ENV=$(SYMFONY_ENV) SSH_KEY=$(SSH_KEY) VIRTUAL_HOST=$(VIRTUAL_HOST) HOSTS_ETC=$(HOSTS_ETC) NPM_CACHE=$(NPM_CACHE) COMPOSER_CACHE=$(COMPOSER_CACHE) NETWORK=$(ROTHENBERG_NETWORK) ENV=$(ENV) SYMFONY_DEBUG=$(SYMFONY_DEBUG) && $(call export-file,$<,$@)

vendor/autoload.php: composer.lock

## Application

.PHONY: start
start: install nginx ## Install all and start application.
ifeq ($(OS),linux)
	@printf "SUCCESS! You can now go to < \033[92mhttp://$(VIRTUAL_HOST)\033[0m >, have a good day!\n"
else
	@printf "Unable to add \`127.0.0.1 $(VIRTUAL_HOST)\` to \`/etc/hosts\` on OSX, please add it manually or configure \`dnsmask\` accordingly (see \`README.md\` for more informations).\n"
	@printf "After doing that, you will be able to access to < \033[92mhttp://$(VIRTUAL_HOST)\033[0m >, have a good day!\n"
endif

.PHONY: stop
stop: docker/stop docker/clean ## Stop application.

.PHONY: restart
restart: stop start ## Stop and start application.

## Uninstall

uninstall/.env: uninstall/host

uninstall/symfony: uninstall/web uninstall/var

.PHONY: uninstall/web
uninstall/web: uninstall/web/bundles

.PHONY: uninstall/host
ifneq ($(OS),linux)
uninstall/host:
else
uninstall/host: | bin/docker-compose
	bin/docker-compose run --rm hosts bash -c "sed -i '/^127.0.0.1 $(VIRTUAL_HOST)/d' $(HOSTS_ETC)/hosts"
endif

## Nginx

.PHONY: nginx
nginx: bin/docker-compose
	bin/docker-compose up -d nginx

## Node

bin/npm bin/node: | bin/.
	$(call install,$@)

bin/node: | env/node

.PHONY: node
node: | env/node

env/node:
	$(MKDIR) $@
