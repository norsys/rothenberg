#!/bin/sh

if [ -z "$TARGET" ]; then
	TARGET=app
fi

if [ -z "$VERSION" ]; then
	VERSION=dev-master
fi

composer config repositories.norsys-rothenberg vcs $DOCKER_VCS
composer require --dev --ignore-platform-reqs --no-suggest norsys/rothenberg:$VERSION

make -f vendor/norsys/rothenberg/install.mk install TARGET=$TARGET COMPOSER_BIN=$(which composer) PHP_BIN=$(which php)
