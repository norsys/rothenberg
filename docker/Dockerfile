FROM php:cli
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
RUN apt-get remove -qqy libgnutls-deb0-28 2>/dev/null || true
RUN apt-get update -qq && apt-get install -qqy wget curl git zlib1g-dev libpcre3-dev libzip-dev && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install zip
RUN mkdir /rothenberg /src /.composer
COPY composer.sh rothenberg.sh /rothenberg/
RUN chmod 777 /rothenberg/*.sh
RUN /rothenberg/composer.sh
RUN mv composer.phar /usr/local/bin/composer
RUN chmod 777 /usr/local/bin/composer
ENV COMPOSER_HOME=/ COMPOSER_CACHE_DIR=/.composer/cache COMPOSER_ALLOW_SUPERUSER=1 SSH_KEY=id_rsa GIT_SSH_COMMAND=ssh\ -i\ /.ssh/$SSH_KEY\ -o\ UserKnownHostsFile=/dev/null\ -o\ StrictHostKeyChecking=no
WORKDIR /src
VOLUME [ "/src", "/.ssh", "/.composer", "/etc" ]
CMD /rothenberg/rothenberg.sh
