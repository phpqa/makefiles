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

#. Provide the PHP variable as installed by this file
PHP?=bin/php
ifeq ($(PHP),bin/php)
PHP_DEPENDENCY?=bin/php
else
PHP_DEPENDENCY?=$(wildcard $(PHP))
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
	@printf "%s\\n" "    php \$$(dirname \$$(readlink -f "\$$0"))/composer check-platform-reqs --no-plugins --quiet \\" >> "$(@)"
	@printf "%s\\n" "        || printf \"\033[33m%s\033[0m\\\\n\" \"Your PHP does not fit the expected requirements\"" >> "$(@)"
	@printf "%s\\n" "    set -- php \"\$$@\"" >> "$(@)"
	@printf "%s\\n" "else" >> "$(@)"
	@printf "%s\\n" "    if test -n \"\$$($(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter \"status=running\" | grep \"$(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP)\" 2>/dev/null)\"; then" >> "$(@)"
	@printf "%s\\n" "        set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec -T $(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP) php \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "    else" >> "$(@)"
	@printf "%s\\n" "        set -- $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) run -T --rm --no-deps $(DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP) php \"\$${@--r}\"" >> "$(@)"
	@printf "%s\\n" "    fi" >> "$(@)"
	@printf "%s\\n\\n" "fi" >> "$(@)"
	@printf "%s\\n" "$(if $(DOCKER_COMPOSE_DIRECTORY),cd \"$(DOCKER_COMPOSE_DIRECTORY)\" && )exec \"\$$@\"" >> "$(@)"
	@chmod +x "$(@)"