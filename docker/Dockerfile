FROM php:cli
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update -qq && apt-get install -qqy git/testing zlib1g-dev libpcre3-dev && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install zip
RUN mkdir /rothenberg /src /.composer
COPY composer.phar rothenberg.sh /rothenberg/
RUN mv /rothenberg/composer.phar /usr/local/bin/composer
RUN chmod 777 /rothenberg/rothenberg.sh
ENV COMPOSER_HOME=/ COMPOSER_CACHE_DIR=/.composer/cache COMPOSER_ALLOW_SUPERUSER=1 SSH_KEY=id_rsa
ENV GIT_SSH_COMMAND=ssh\ -i\ /.ssh/$SSH_KEY\ -o\ UserKnownHostsFile=/dev/null\ -o\ StrictHostKeyChecking=no
WORKDIR /src
VOLUME [ "/src", "/.ssh", "/.composer", "/etc" ]
CMD /rothenberg/rothenberg.sh
