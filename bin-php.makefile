###
##. Configuration
###

# TODO Move to DOCKER_CONTAINER_NAME_FOR_PHP
DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP?=
ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP before including this file.)
endif

#. Provide the PHP variable as installed by this file
PHP?=bin/php
ifeq ($(PHP),bin/php)
PHP_DEPENDENCY?=bin/php
else
PHP_DEPENDENCY?=$(wildcard $(PHP))
endif
PHP_FLAGS?=
PHP_MEMORY_LIMIT?=
ifneq ($(PHP_MEMORY_LIMIT),)
ifeq ($(findstring memory_limit,$(PHP_FLAGS)),)
PHP_FLAGS+=-d memory_limit="$(PHP_MEMORY_LIMIT)"
endif
endif

###
## PHP
###

# Create a bin/php file
# TODO split bin/php between local php check, docker and docker-compose
# TODO try to find the container name for php automagically based on docker-compose image
bin/php: $(MAKEFILE_LIST) $(if $(wildcard $(DEFAULT_ENV_FILE)),$(DEFAULT_ENV_FILE))
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@printf "%s\\n" "#!/usr/bin/env sh" > "$(@)"
	@printf "%s\\n\\n" "set -e" >> "$(@)"
	@printf "%s\\n" "if ! command -v $(DOCKER_COMPOSE) > /dev/null 2>&1; then" >> "$(@)"
	@printf "%s\\n" "    if -f \$$(dirname \$$(readlink -f "\$$0"))/composer; then" >> "$(@)"
	@printf "%s\\n" "        php \$$(dirname \$$(readlink -f "\$$0"))/composer check-platform-reqs --no-plugins --quiet \\" >> "$(@)"
	@printf "%s\\n" "            || php \$$(dirname \$$(readlink -f "\$$0"))/composer check-platform-reqs --no-plugins" >> "$(@)"
	@printf "%s\\n" "    fi" >> "$(@)"
	@printf "%s\\n" "    set -- php$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$$@\"" >> "$(@)"
	@printf "%s\\n" "else" >> "$(@)"
	@printf "%s\\n" "    if test -n \"\$$($(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter \"status=running\" | grep \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" 2>/dev/null)\"; then" >> "$(@)"
	@printf "%s\\n" "        set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec -T $(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP) php$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "    else" >> "$(@)"
	@printf "%s\\n" "        set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) run -T --rm --no-deps $(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP) php$(if $(PHP_FLAGS), $(PHP_FLAGS)) \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "    fi" >> "$(@)"
	@printf "%s\\n\\n" "fi" >> "$(@)"
	@printf "%s\\n" "$(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )exec \"\$$@\"" >> "$(@)"
	@chmod +x "$(@)"
