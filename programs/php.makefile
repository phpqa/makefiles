###
##. Configuration
###

PHP_DEPENDENCY?=php.assure-usable
ifeq ($(PHP_DEPENDENCY),)
$(error The variable PHP_DEPENDENCY should never be empty)
endif

PHP_DIRECTORY?=.
ifeq ($(PHP_DIRECTORY),)
$(error The variable PHP_DIRECTORY should never be empty)
endif

PHP?=$(if $(wildcard $(filter-out .,$(PHP_DIRECTORY))),$(PHP_DIRECTORY)/)bin/php
ifeq ($(PHP),)
$(error The variable PHP should never be empty)
endif

PHP_FLAGS?=
PHP_MEMORY_LIMIT?=
ifneq ($(PHP_MEMORY_LIMIT),)
ifeq ($(findstring memory_limit,$(PHP_FLAGS)),)
PHP_FLAGS+=-d memory_limit="$(PHP_MEMORY_LIMIT)"
endif
endif

# TODO split bin/php between local php check, docker and docker-compose
# TODO try to find the container name for php automagically based on docker-compose image
# TODO Add some checks for DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP
DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP?=

###
##. PHP
##. A popular general-purpose scripting language that is especially suited to web development
##. @see https://www.php.net/
###

#. Assure that PHP is usable
php.assure-usable: | bin/php
	@if test -z "$$($(PHP) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use PHP as "$(value PHP)".'; \
		$(PHP) --version; \
		exit 1; \
	fi
.PHONY: php.assure-usable

# Create a bin/php file
# @see https://www.php.net/
bin/php: $(MAKEFILE_LIST) $(if $(wildcard $(DEFAULT_ENV_FILE)),$(DEFAULT_ENV_FILE))
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@printf "%s\\n" "#!/usr/bin/env sh" > "$(@)"
	@printf "%s\\n\\n" "set -e" >> "$(@)"
ifneq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP),)
	@printf "%s\\n" "if test -n \"\$$($(subst $$,\$$,$(subst ",\",$(DOCKER_COMPOSE))) ps --services --filter \"status=running\" | grep \"^$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\$$\" 2>/dev/null)\"; then" >> "$(@)"
	@printf "%s\\n" "    $(subst $$,\$$,$(subst ",\",$(DOCKER_COMPOSE) exec$(if $(DOCKER_COMPOSE_EXEC_FLAGS), $(DOCKER_COMPOSE_EXEC_FLAGS)))) \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$${@--a}\"" >> "$(@)"
	@printf "%s\\n" "else" >> "$(@)"
	@printf "%s\\n" "    $(subst $$,\$$,$(subst ",\",$(DOCKER_COMPOSE) run$(if $(DOCKER_COMPOSE_RUN_FLAGS), $(DOCKER_COMPOSE_RUN_FLAGS)))) \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" php$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$${@--a}\"" >> "$(@)"
	@printf "%s\\n" "fi" >> "$(@)"
else
ifneq ($(PHP),)
	@printf "%s\\n" "if test -f \$$(dirname \$$(readlink -f "\$$0"))/composer; then" >> "$(@)"
	@printf "%s\\n" "    $(PHP) \$$(dirname \$$(readlink -f "\$$0"))/composer check-platform-reqs --no-plugins --quiet \\" >> "$(@)"
	@printf "%s\\n" "        || $(PHP) \$$(dirname \$$(readlink -f "\$$0"))/composer check-platform-reqs --no-plugins" >> "$(@)"
	@printf "%s\\n" "fi" >> "$(@)"
	@printf "%s\\n" "$(PHP)$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$$@\"" >> "$(@)"
else
	$(error Could not find a way to run PHP)
endif
endif
	@chmod +x "$(@)"
