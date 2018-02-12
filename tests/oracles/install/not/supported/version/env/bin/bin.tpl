#!/usr/bin/env sh

set -e

exec ./bin/docker-compose run --rm php-cli php -f ${BINARY} -- "${ARGUMENTS}"
