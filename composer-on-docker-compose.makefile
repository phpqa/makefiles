###
##. Configuration
###

DOCKER_SOCKET?=/var/run/docker.sock

DOCKER?=$(shell command -v docker || which docker 2>/dev/null)

DOCKER_COMPOSE?=$(shell command -v docker-compose || which docker-compose 2>/dev/null)
DOCKER_COMPOSE_EXTRA_FLAGS?=
DOCKER_COMPOSE_FLAGS?=$(if $(DOCKER_COMPOSE_EXTRA_FLAGS), $(DOCKER_COMPOSE_EXTRA_FLAGS))
DOCKER_COMPOSE_DIRECTORY?=

ifeq ($(DOCKER),)
$(error Please install docker.)
endif

ifeq ($(DOCKER_COMPOSE),)
$(error Please install docker-compose.)
endif

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP?=
ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP before including this file.)
endif

COMPOSER_IMAGE?=composer
COMPOSER_VERSION?=

###
## Composer
###

#. Create the bin directory
bin:
	@if test ! -d "$(@)"; then mkdir -p "$(@)"; fi

# Create a bin/php file
bin/php: $(MAKEFILE_LIST) $(if wildcard .env,.env) | bin
	@printf "%s\\n" "#!/usr/bin/env sh" > "$(@)"
	@printf "%s\\n\\n" "set -e" >> "$(@)"
	@printf "%s\\n" "if test -n \"\$$($(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter \"status=running\" | grep \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" 2>/dev/null)\"; then" >> "$(@)"
	@printf "%s\\n" "    set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec -T \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "else" >> "$(@)"
	@printf "%s\\n" "    set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) run -T --rm --no-deps \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "fi" >> "$(@)"
	@printf "%s\\n" "$(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )exec \"\$$@\"" >> "$(@)"
	@chmod +x "$(@)"

ifneq ($(DOCKER),)
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | bin
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || -f "bin/composer"; then rm -f "bin/composer"; fi)
	@$(DOCKER) image pull $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@$(DOCKER) run --rm --init --pull=missing --volume "$(CWD)":"/app" --workdir "/app" $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION)) cat /usr/bin/composer > "$(@)"
	@$(DOCKER) image rm $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@chmod +x "$(@)"
else
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | bin bin/php
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || -f "bin/composer"; then rm -f "bin/composer"; fi)
	@bin/php -r "file_put_contents('setup.php', fopen('https://getcomposer.org/installer', 'r'), LOCK_EX);"
	@bin/php -r "file_put_contents('setup.sig', fopen('https://composer.github.io/installer.sig', 'r'), LOCK_EX);"
	@bin/php -r " \
		if (hash_file('SHA384', 'setup.php') !== trim(file_get_contents('setup.sig'))) { \
			echo 'Installer corrupt'; \
			unlink('setup.php'); \
			unlink('setup.sig'); \
			echo PHP_EOL; \
		} \
	"
	@if test ! -d "$(dir $(@))"; then bin/php -r "mkdir('$(dir $(@))', 0777, true);"; fi
	@bin/php setup.php --no-ansi --install-dir=$(dir $(@)) --filename=$(notdir $(@))$(if $(COMPOSER_VERSION), --version=$(COMPOSER_VERSION))
	@bin/php -r "unlink('setup.php');"
	@bin/php -r "unlink('setup.sig');"
	@chmod +x "$(@)"
endif

ifneq ($(COMPOSER_VERSION),)
# Download Composer to bin/composer
bin/composer: bin/composer-$(COMPOSER_VERSION)
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@if test -L "$(@)"; then rm -f "$(@)"; fi
	@ln -s "$(notdir $(<))" "$(@)"
endif

# Create a composer.json file
composer.json: | bin/php bin/composer
	@if test ! -f "$(@)"; then \
		bin/php bin/composer init --no-interaction --name vendor/project; \
	fi

# Build the composer.lock file
composer.lock: composer.json | bin/php bin/composer
	@if test ! -f "$(@)"; then \
		bin/php bin/composer install --no-progress --no-suggest; \
	else \
		bin/php bin/composer update --lock; \
		touch "$(@)"; \
	fi

# Build the vendor directory
vendor: composer.lock | bin/php bin/composer
	@bin/php bin/composer install --no-progress --no-suggest
	@touch "$(@)"
