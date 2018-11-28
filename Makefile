THIS_FILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR := $(dir $(THIS_FILE))

VERSION ?= dev-master
SSH_KEY ?= id_rsa
RM := $(RM) -r
MKDIR := mkdir -p
CP := cp -r
MV := mv -f

REPOSITORY_STATUS := $(shell git status --porcelain | wc -l)

include resources/env/utils.mk

define check-repository
ifneq "$(strip $(REPOSITORY_STATUS))" "0"
$$(error Repository is not clean, please add and commit files);
endif
endef

define create-oracle
$(RM) $1
$(MKDIR) $(dir $1)
$(CP) $2 $1
sed -e "s#\"norsys/rothenberg\": \"dev-[^\"]*\"#\"norsys/rothenberg\": \"dev-$$(git rev-parse --abbrev-ref HEAD)\"#g" $1/composer.json > $1/composer.json.oracle
$(MV) $1/composer.json.oracle $1/composer.json
git -C $1 init
git -C $1 add .
git -C $1 commit -m "Oracle creation." --no-gpg-sign
endef

define assert
if [ $1 ]; then $(call success,$2) else $(call failure,$2,$3) fi
endef

define success
$(call colorize,92m,SUCCESS for $1)
endef

define failure
$(call colorize,91m,FAILURE for $1) if [ "$2" ]; then eval $2; fi; exit 1;
endef

define colorize
printf "\n\n=> \033[$1$2!\033[0m\n\n";
endef

.SUFFIXES:

.DELETE_ON_ERROR:

# Docker

docker/%: DOCKER_IMAGE ?= hub.docker.com/norsys/rothenberg
docker/%: DOCKER_TAG ?= latest
docker/% test/%: DOCKER_BIN ?= $(call locate-binary,docker)

.PHONY: docker/build
docker/build:
	$(DOCKER_BIN) build -t $(DOCKER_IMAGE):$(DOCKER_TAG) ./docker

.PHONY: docker/hub
docker/hub: docker
	$(DOCKER_BIN) push $(DOCKER_IMAGE):$(DOCKER_TAG)

# Tests

.PHONY: tests-clean
tests-clean: ## Clean tests temporary files
	$(RM) tests/cases

.PHONY: tests
tests: test/install/app test/install/bundle test/update/app test/update/bundle test/bad/target test/rothenberg/update/uninstall test/install/not/supported/version ## Run tests

test/install/%:
	$(eval $(check-repository))
	$(DOCKER_BIN) system prune -f
	$(call create-oracle,tests/cases/install/$*,tests/oracles/install/$*)
	$(RM) tests/cases/install/$*/*
	export TARGET=$(notdir $@) VERSION=dev-$(GIT_BRANCH) SSH_KEY=$(SSH_KEY) && ./install.sh --build-docker-image --vcs=/vcs/rothenberg --directory=tests/cases/install/$*
	git -C tests/cases/install/$* add .
	git -C tests/cases/install/$* diff --cached -- ':(exclude)composer.lock' > tests/cases/install/oracle.$*.diff
	@$(call assert,! -s tests/cases/install/oracle.$*.diff,$@,cat tests/cases/install/oracle.$*.diff)
	@$(call assert,-z "$$(find tests/cases/install/$* -not -uid $$(id -u))",All files are owned by current user for $@)

test/update/%:
	$(eval $(check-repository))
	$(DOCKER_BIN) system prune -f
	$(call create-oracle,tests/cases/update/$*,tests/oracles/update/$*)
	$(MAKE) -C tests/cases/update/$* rothenberg/update
	git -C tests/cases/update/$* add .
	git -C tests/cases/update/$* diff -- `grep -lr '# This file MUST NOT be updated by Rothenberg' tests/cases/update/$* | grep -v vendor/norsys/rothenberg`':(exclude)composer.lock' > tests/cases/update/oracle.$*.diff
	@$(call assert,! -s tests/cases/update/oracle.$*.diff,$@,cat tests/cases/update/oracle.$*.diff)
	@$(call assert,-z "$$(find tests/cases/update/$* -not -uid $$(id -u))",All files are owned by current user for $@)

.PHONY: test/bad/target
test/bad/target:
	$(eval $(check-repository))
	$(DOCKER_BIN) system prune -f
	$(RM) tests/cases/bad/target
	$(MKDIR) tests/cases/bad/target
	-export TARGET=foo VERSION=dev-$(GIT_BRANCH) SSH_KEY=$(SSH_KEY) && ./install.sh --build-docker-image --vcs=/vcs/rothenberg --directory=tests/cases/bad/target 2> tests/cases/bad/target/install.log
	@$(call assert,"$$(tail -n 1 tests/cases/bad/target/install.log | grep -c 'Target foo is invalid!')" = '1',$@)

.PHONY: test/rothenberg/update/uninstall
test/rothenberg/update/uninstall:
	$(eval $(check-repository))
	$(DOCKER_BIN) system prune -f
	$(RM) tests/cases/rothenberg/update/uninstall
	$(MKDIR) tests/cases/rothenberg/update/uninstall
	$(call create-oracle,tests/cases/rothenberg/update/uninstall,tests/oracles/rothenberg/update/uninstall)
	-$(MAKE) -C tests/cases/rothenberg/update/uninstall rothenberg/update 2> tests/cases/rothenberg/update/uninstall.log
	@$(call assert,"$$(tail -n 1 tests/cases/rothenberg/update/uninstall.log | grep -c 'Please install rothenberg before update it!')" = '1',$@)

.PHONY: test/install/not/supported/version
test/install/not/supported/version:
	$(eval $(check-repository))
	$(DOCKER_BIN) system prune -f
	$(RM) tests/cases/install/not/supported/version
	$(MKDIR) tests/cases/install/not/supported/version
	$(call create-oracle,tests/cases/install/not/supported/version,tests/oracles/install/not/supported/version)
	export TARGET=$(notdir $@) VERSION=dev-$(GIT_BRANCH) SSH_KEY=$(SSH_KEY) && ./install.sh --build-docker-image --vcs=/vcs/rothenberg --directory=tests/cases/install/not/supported/version --symfony-version=4 > tests/cases/install/not/supported/version/version.log
	@$(call assert, "$$(tail -n 1 tests/cases/install/not/supported/version/version.log | grep -c 'Symfony version lesser or greater than 3 is not currently supported.')" = '1', $@)

test/bad/target test/install/%: GIT_BRANCH ?= $(shell git -C $(realpath $(THIS_DIR)) rev-parse --abbrev-ref HEAD)

# Help

help: ## Display this help.
	@printf "$$(cat $(MAKEFILE_LIST) | egrep -h '^[^:]+:[^#]+## .+$$' | sed -e 's/:[^#]*##/:/' -e 's/\(.*\):/\\033[92m\1\\033[0m:/' | sort -d | column -c2 -t -s :)\n"
