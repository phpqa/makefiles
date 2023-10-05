###
## About
###

include ../../base.makefile
include ../../help.makefile

###
## Dependencies
###

include ../../programs/git.makefile
include ../../programs/jq.makefile
include ../../programs.makefile

###
## Docker & Compose
###

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP:=php

include ../../programs/docker.makefile

###
## Docker Tools
###

TRAEFIK_PROVIDERS_DOCKER_NETWORK=traefik
include ../../docker-tools/traefik.makefile
include ../../programs/curl.makefile # Dependency for Dozzle
include ../../docker-tools/dozzle.makefile

###
## DotEnv Linter
###

include ../../generic-tools/dotenv-linter.makefile

###
## PHP & Composer
###

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP=php
include ../../programs/php.makefile
include ../../programs/composer.makefile

###
## Quality Assurance Tools
###

include ../../php/tools/composer.makefile
include ../../php/tools/composer-normalize.makefile
include ../../php/tools/franzl-studio.makefile
include ../../php/tools/friendsofphp-php-cs-fixer.makefile
include ../../php/tools/php-parallel-lint.makefile
include ../../php/tools/phpstan.makefile
include ../../php/tools/qossmic-deptrac.makefile
include ../../php/tools/rector.makefile
include ../../php/tools/squizlabs-php_codesniffer.makefile
include ../../php/tools/vimeo-psalm.makefile
include ../../php/combined/php-check.makefile
include ../../php/combined/php-fix.makefile
include ../../php/tools/phpunit.makefile
include ../../php/combined/php-test.makefile

###
## Tooling Helpers
###

# Install all PHP related dev tools, as registered by the included makefiles above
install-php-tools: | \
	compose.service.php.ensure-running \
	vendor \
	php.check.install \
	php.fix.install \
	php.test.install
.PHONY: install-php-tools

# Configure Composer more strict
configure-composer-strict: | \
	compose.service.php.ensure-running \
	$(COMPOSER_LOCK) \
	composer.configure-strict \
	composer.check-platform-reqs \
	composer-normalize \
	composer.validate
.PHONY: configure-composer-strict

###
## Typical PHP Project
###

# Create the .env file
.env: .env.dist
	@if test ! -f "$(@)"; then cp "$(<)" "$(@)"; fi
	@touch "$(@)"

# Prepare the setup
prepare: .env dotenv-linter.compare vendor
	@sed -i "s#UID=.*#UID=$$(id -u)#" ".env"
	@sed -i "s#GID=.*#GID=$$(id -g)#" ".env"
.PHONY: prepare

# Build the images
build: compose.build; @true
.PHONY: build

# Start the services
start: DOCKER_COMPOSE_SERVICES_TO_LOG_DURING_UP_UNTIL_SUCCESSFUL_EXIT=php-sidecar
start: traefik.start prepare dozzle.start compose.up compose.service.php.ensure-running list; @true
.PHONY: start

#. List the urls to the services
list: | traefik.list dozzle.list
	@printf "Open Application: %s\n" "APPLICATION URL GOES HERE"
.PHONY: list

# Open a shell
shell: traefik.start compose.service.php.sh; @true
.PHONY: shell

# Open a bash
bash: traefik.start compose.service.php.bash; @true
.PHONY: bash

# Stop the services
stop: compose.down; @true
.PHONY: stop

# Clear the services
clear: compose.clear traefik.clear dozzle.clear container.network.traefik.remove; @true
.PHONY: clear

# Clean all directories and files
clean: | clear
	-@rm -rf bin
	-@rm -rf .composer
	-@rm -rf vendor
	-@rm -f composer.json
	-@rm -f composer.lock
.PHONY: clean

###
## Traefik tests
###

# Test if the external Traefik network does not get in the way
test-traefik-external-network:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" compose.service.traefik.ensure-stopped
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" container.network.traefik.remove
	@if test -f composer.lock; then touch composer.lock; fi
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" start
