###
##. Configuration
###

DOCKER_COMPOSE_DIRECTORY_FOR_PHP?=
DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP?=

ifeq ($(DOCKER_COMPOSE_DIRECTORY_FOR_PHP),)
$(error Please provide the variable DOCKER_COMPOSE_DIRECTORY_FOR_PHP before including this file.)
endif

ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP before including this file.)
endif

###
## Composer
###

#. Create the bin directory
bin:
	@if test ! -d "$@"; then mkdir -p "$@"; fi

# Create a bin/php file
bin/php: $(MAKEFILE_LIST) $(if wildcard .env,.env) | bin
	@printf "%s\\n" "#!/usr/bin/env sh" > "$@"
	@printf "%s\\n\\n" "set -e" >> "$@"
	@printf "%s\\n" "pushd \"$(DOCKER_COMPOSE_DIRECTORY_FOR_PHP)\" > /dev/null" >> "$@"
	@printf "%s\\n" "if test -n \"\$$(docker-compose$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter \"status=running\" | grep \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" 2>/dev/null)\"; then" >> "$@"
	@printf "%s\\n" "    set -- docker-compose$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec -T \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php \"\$${@--r}\"" >> "$@"
	@printf "%s\\n" "else" >> "$@"
	@printf "%s\\n" "    set -- docker-compose$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) run -T --rm --no-deps \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php \"\$${@--r}\"" >> "$@"
	@printf "%s\\n" "fi" >> "$@"
	@printf "%s\\n" "popd > /dev/null" >> "$@"
	@printf "%s\\n" "cd \"$(DOCKER_COMPOSE_DIRECTORY_FOR_PHP)\" && exec \"\$$@\"" >> "$@"
	@chmod +x "$@"

ifneq ($(DOCKER_EXECUTABLE),)
# Download Composer to bin/composer
bin/composer: | bin
	@rm -f "$@"
	@if test ! -d "$(dir $@)"; then mkdir -p "$(dir $@)"; fi
	@$(DOCKER_EXECUTABLE) image pull $(COMPOSER_IMAGE):$(COMPOSER_VERSION)
	@$(DOCKER_EXECUTABLE) run --rm --init --pull=missing --volume "$(CWD)":"/app" --workdir "/app" $(COMPOSER_IMAGE):$(COMPOSER_VERSION) cat /usr/bin/composer > "$@"
	@$(DOCKER_EXECUTABLE) image rm $(COMPOSER_IMAGE):$(COMPOSER_VERSION)
	@chmod +x "$@"
else
#. Download Composer to bin/composer
bin/composer: | bin bin/php
	@rm -f "$@"
	@bin/php -r "file_put_contents('setup.php', fopen('https://getcomposer.org/installer', 'r'), LOCK_EX);"
	@bin/php -r "file_put_contents('setup.sig', fopen('https://composer.github.io/installer.sig', 'r'), LOCK_EX);"
	@bin/php -r " \
		if (hash_file('SHA384', 'setup.php') !== trim(file_get_contents('setup.sig'))) { \
			echo 'Installer corrupt'; \
			unlink('setup.php'); \
			unlink('setup.sig'); \
		} \
		echo PHP_EOL; \
	"
	@bin/php -r "mkdir('$(dir $@)', 0777, true);"
	@bin/php setup.php --no-ansi --install-dir=$(dir $@) --filename=$(notdir $@) --version=$(COMPOSER_VERSION)
	@bin/php -r "unlink('setup.php');"
	@bin/php -r "unlink('setup.sig');"
endif

# Create a composer.json file
composer.json: | bin/php bin/composer
	@if test ! -f "$@"; then \
		bin/php bin/composer init --no-interaction --name vendor/project; \
	fi

# Build the composer.lock file
composer.lock: composer.json | bin/php bin/composer
	@if test ! -f "$@"; then \
		bin/php bin/composer install --no-progress --no-suggest; \
	else \
		bin/php bin/composer update --lock; \
		touch "$@"; \
	fi

# Build the vendor directory
vendor: composer.lock | bin/php bin/composer
	@bin/php bin/composer install --no-progress --no-suggest
	@touch "$@"
