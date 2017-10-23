# Rothenberg

`Rothenberg` allow a developper to create or maintain a Symfony application or a Symfony bundle very easily and without install something on his workstation (Mac or PC, Windows is not currently supported).  
To do that, it use `docker`, `docker-compose`, `make` and `composer`.  
`Rothenberg` is not a standalone project, and it must be used in the context of an another project.  
In the following, we will assume that `Rothenberg` was used from the directory `path/to/project`.

## TL;DR

To use `Rothenberg` to develop or maintain a Symfony application, execute the following command in a terminal:

```
wget -O - https://github.com/norsys/rothenberg/raw/master/install.sh | sh
```

Or to use `Rothenberg` in the context of a Symfony bundle, do:

```
(export TARGET=bundle; wget -O - https://github.com/norsys/rothenberg/raw/master/install.sh | sh)
```

But… maybe you should read the following informations before executing one of these commands!

## Objectives

`Rothenberg` must allow a user to install an isolated Symfony environment on its workstation easily and rapidily in order to develop an application or a bundle.  
Morever, the user must only have a UNIX operating system, `docker`, a CLI HTTP client (aka *wget* or *curl*) and `make` to use it.  
It must be used for a "from scratch" project or in the context of an already existing project.  
And at least, it must be simple, easy and intuitive to use.

## Features

In the following, we assume that the command `make -f vendor/norsys/rothenberg/Makefile install` was made in the directory `path/to/project`.

### Docker and docker-compose configuration

`Rothenberg` create a `docker-compose.yml` with some services pre-configured and an empty `docker-compose.override.yml` (only if this file does not exist) in the directory `path/to/project`.  
If you want to override some services's configuration, use [`docker-compose.override.yml`](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files).

### Docker images management

`Rothenberg` pulls the lastest version of each docker image via `make start` or `make restart` (see below for more information about these commands).  
These images are:

- `nginx` ;
- `php-fpm` ;
- `php-cli` ;
- `composer` ;
- `node`.

It's possible to disable this feature via the `.rothenberg.config` file.

### Default PHP configuration for `CLI` and `FPM`

`Rothenberg` provides a `php.ini` for CLI and FPM in `path/to/project/env/php/cli` and `path/to/project/env/php/fpm` respectively.

### Helpers to hide `docker` and `docker-compose`

`Rothenberg` provides several helpers in `path/to/project/bin` to hide `docker` and `docker-compose` complexity.  
So, all scripts in `path/to/project/bin` can be run in the traditional way even if `docker` is used in the background.  
For example, to update PHP depedencies, just do `bin/composer update`.

### Atoum configuration

`Rothenberg` installs files `path/to/project/.atoum.php`, an atoum runner and a base test class in `path/to/project/tests/units`.

### Automated `nginx` virtual host management

`Rothenberg` provides an automated `nginx` virtual host management via the `make` variable `VIRTUAL_HOST`.  
To define the virtual host for your project, define its value before including `./env/Makefile` (see below for more information about that):

```
VIRTUAL_HOST := foo.bar

include env/Makefile
```

### Networking

`Rothenberg` allows you to share an [`nginx-proxy`](https://github.com/jwilder/nginx-proxy) docker's service between several projects, or any other services.  
For that purpose, it creates a network named according to the value of make's `ROTHENBERG_NETWORK` variable, which has `rothenberg` as default value.  
If you want to override its value, in the project's `Makefile`, just add `ROTHENBERG_NETWORK := yourNetworkName` before including `env/Makefile` (see below for more information about that).

### Environment management

`Rothenberg` allows you to install a project in several environments using the `make` variable `ENV` and [`SYMFONY_ENV`](http://symfony.com/doc/current/configuration/environments.html).  
Default value of `ENV` is `dev`, and the default value of `SYMFONY_ENV` is `ENV`.  
So, to install a project in a `prod` environmment using the `dev` Symfony environment, just do:

```
# make install ENV=prod SYMFONY_ENV=dev
```

By default, the symfony debug mode is enabled, but you can disable it using the `make` variable `SYMFONY_DEBUG`:

```
# make install SYMFONY_DEBUG=false
```

### Private PHP package management

`Rothenberg` can handle SSH key needed to access some private PHP packages via `composer`.  
Out of the box, it will use the key `$(HOME)/.ssh/id_rsa`, but you can override this using `make <target> SSH_KEY=/path/to/your/ssh/key`.
Your secret key will never be copied by `Rothenberg`.

### Default `Makefile`

If your project has no `Makefile` during its installation, `Rothenberg` provides a default `Makefile` for it.  
Moreover, it provides in `path/to/project/env` a `Makefile` with some interesting targets (see below).  
This `Makefile` is already included in the default `Makefile` provided by `Rothenberg`.  
If the project already has a `Makefile` before `Rothenberg` installation, add `include env/Makefile` in it to use `Rothenberg` targets.


### Project Management

`Rothenberg` allows you to use *make* to manage a project, with the following `make` targets:

- `install` install localy `docker-compose`, `php-(?:cli|fpm)`, `composer`, `node`, `npm`, `nginx` and configure them ;
- `reinstall` restart the project ;
- `uninstall` to uninstall the project ;
- `start` start all services needed by the website (`nginx`, `php-fpm`…) ;
- `stop` stop all services needed by the project ;
- `restart` restart all services ;
- `status` display status of each services ;
- `security` to check security of PHP depedencies ;
- `check-style-php` to check PHP coding convention according to `env/php/check-style.xml` ;
- `fix-style-php` to fix PHP coding convention according to `env/php/check-style.xml` ;
- `unit-tests` to run all unit tests ;
- `rothenberg/update` to update `Rothenberg` (see the `Update` section below) ;
- `help` display a tiny help about each of available commands.

Some of these targets are available only if you use `rothenberg` to develop an application.  
Use `make help` to know available targets according to your type of project.

### Git configuration

`Rothenberg` installs files `.gitignore` and `.gitattribute` with default values in the directory `path/to/project`.  
Moreover, it installs a [pre-commit hook](https://git-scm.com/book/it/v2/Customizing-Git-Git-Hooks) to check coding convention via  `make check-style`.

### Assets watcher

`Rothenberg` provides an assets watcher via `bin/watchodg`, which is automaticaly started via `make start` or `make restart`.

## Requierements

- *Unix* (installation process was tested on *Ubuntu* and *OSX*) ;
- *Docker* ;
- *wget* or any equivalent (for install only) ;
- *GNU make* ;
- Internet access.

That's all!

## Installation in a project

You can install `Rothenberg` in a new project or in an existing one.  
For example, if your project is an application located in `path/to/project`:

1. `cd path/to/project` ;
2. Do `wget -O - https://github.com/norsys/rothenberg/raw/bundle/install.sh | sh`.

And if your project is a bundle located in `path/to/project`:

1. `cd path/to/project` ;
2. Do `(export TARGET=bundle; wget -O - https://github.com/norsys/rothenberg/raw/bundle/install.sh | sh)`.

After that, if you already have a `./Makefile`, just add `include env/Makefile` in it to profit of `Rothenberg`'s targets.  
You can also define `VIRTUAL_HOST` variable before including `env/Makefile` (see above for more informations).  
Moreover, you can edit [`./docker-compose.override.yml`](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files) to add specific `docker` services or networks.  
After that, you can add  and commit all new files in your project (yes, really, commit them in your project):

1. `git add .` ;
2. `git commit -m "<WHATEVER YOU WANT>"` ;
3. `git push`.

## Configuration for a project

### Configuration of `docker` and `docker-compose`

If your project needs some aditionnal `docker` services, define them in the [`./docker-compose.override.yml`](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files).  
For example, to add `mysql`, edit `./docker-compose.override.yml` and add this in the `services` section:

```
mysql:
	image: mysql:5.6.31
	volumes:
		- ./var/mysql:/var/lib/mysql
```

If you want to link the `mysql` service to `php-fpm`, add this in the `services` section:

```
php-fpm:
	links:
		- mysql
```

If you want to know all services defined by `Rothenberg`, do `make rothenberg-docker-services`.  
For more informations about `./docker-compose.override.yml`, please read its [official documentation](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files) and the `docker-compose` file [reference](https://docs.docker.com/compose/compose-file/).

### Configuration of `make`

You can add [prerequisites](https://www.gnu.org/software/make/manual/html_node/Rule-Syntax.html#Rule-Syntax) for targets defined by `Rothenberg`.  
For example, if you want to create the directory `var/mysql` via `make`, add in `./Makefile` after the include of `./env/Makefile`:

```
vendor/autoload.php: | var/mysql

uninstall/var: uninstall/var/mysql

var/mysql:
        $(MKDIR) $@
```

Some special targets defined by `Rothenberg` are used in this example:

- `vendor/autoload.php` is the trigger for `vendor` installation via [`composer`](https://getcomposer.org) ;
- `uninstall/var` is the target used to clean the `path/to/project/var` directory ;

Moreover, the target `uninstall/var/mysql` is handled by the [pattern rule](https://www.gnu.org/software/make/manual/html_node/Pattern-Intro.html#Pattern-Intro) `uninstall/%` which delete any file or directory defined by wildcard `%`.  

If you want to know all targets defined by `Rothenberg` to add some prerequisites to them, just do `make rothenberg-targets`.  
For more informations about `make`' syntax and features, please read its [official documentation](https://www.gnu.org/software/make/manual/html_node/).

### Configuration of `PHP`

You can customize PHP's configuration in `CLI` and `FPM` context.  
To do that for `CLI` context, edit `path/to/project/env/php/cli/php.ini` (or `path/to/project/env/php/fpm/php.ini` for `FPM`) and execute `make restart`.
For more information about PHP configuration, please read its [official documentation](http://php.net/manual/en/ini.core.php).

### Check styling

Out of the box, `Rothenberg` provides PHP style checking configured via `path/to/project/env/check-style.xml` and `make check-style`, but you can add style checking for some other languages.
For example, to add style checking for JavaScript using [`eslint`](http://eslint.org), add this in `path/to/project/Makefile`:

```
check-style: check-style-js

check-style-js: | bin/node ## Check coding conventions for JavaScript.
	bin/node eslint -c .eslintrc --ignore-path .eslintignore ./src
```

## Update

To update `Rothenberg` in a project, just do:

1. `make rothenberg/update` ;
2. `git add .` ;
3. `git commit -m "<WHATEVER YOU WANT>"` ;
4. `git push`.

## Houston? We've got a problem!

First, don't panic.
Then execute `docker system prune -f` to clean the docker environment, and try to reproduce the problem.  
If the problem disappears, say thanks to Gandalf and enjoy!  
But if the problem always exists, open an issue to help us to improve `rothenberg`.  

### Guidelines to open an issue

Please, describe your problem precisely and give maximum information about your environment:

- Operating system ;
- `docker` version, do `docker --version` to obtain it ;
- `docker-compose` version, do `docker-compose --version` to obtain it ;
- `make version`, do `make --version` to obtain it ;
- Give output of `docker ps -a` ;
- Give output of `docker network ls` ;

Moreover, if you encounter a problem during a `make` command execution, reexecute it with `make <YOUR TARGET HERE> WITH_DEBUG=yes`, and add the output to your issue.  

## Contributing

### About testing

There are some `make` targets to test `Rothenberg`, specialy install and update of bundle and application.  
To run them, just do `make tests`.  
Please, do not omit to update tests before implemeting new feature or doing a bug fix.  
To update tests, just update the content of the `references` directory.

### About workflow

We're using pull request to introduce new features and bug fixes.  
Please, try to be explicit in your commit messages:

1. Explain why the change was made ;
2. Explain technical implementation (you can provide links to any relevant tickets, articles or other resources).

You can use the following template:

```
# If applied, this commit will...

# Explain why this change is being made

# Provide links to any relevant tickets, articles or other resources
```

To use it, just put it in a text file in (for example) your home and define it as a template:

```
# git config --global commit.template ~/.git_commit_template.txt
```

## Languages and tools

- [*docker*](https://docs.docker.com) ;
- [*docker-compose*](https://docs.docker.com/compose/) ;
- [*atoum*](http://docs.atoum.org) ;
- [*make*](https://www.gnu.org/software/make/manual/make.html) ;
- [*Symfony*](http://symfony.com/doc/current/index.html).

## Why `Rothenberg`?

[David Rothenberg](http://www.davidrothenberg.net) is a book author and a song composer which has made music with whales.  
This project uses `docker`, which has a whale as logo, and `composer`, `docker-compose` to set up a symfony environment.  
So, `Rothenberg` seems to be a good choice as name ;).
