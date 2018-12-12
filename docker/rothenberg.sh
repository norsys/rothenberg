#!/bin/sh

if [ -z "$TARGET" ]; then
	TARGET=app
fi

if [ -z "$VERSION" ]; then
	VERSION=dev-master
fi

if [ ! -z "$DOCKER_VCS" ]; then
	composer config repositories.norsys-rothenberg vcs $DOCKER_VCS
fi

composer require --dev --ignore-platform-reqs --no-suggest norsys/rothenberg:$VERSION

make -f vendor/norsys/rothenberg/install.mk install TARGET=$TARGET COMPOSER_BIN=$(which composer 2>/dev/null) PHP_BIN=$(which php 2>/dev/null) SYMFONY_VERSION=$SYMFONY_VERSION WITH_DEBUG=$WITH_DEBUG SSH_KEY=$SSH_KEY
