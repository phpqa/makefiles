###
##. Configuration
###

DOCKER?=$(shell command -v docker || which docker 2>/dev/null)
DOCKER_SOCKET?=/var/run/docker.sock
DOCKER_REGISTRIES?=
ifeq ($(DOCKER),)
$(error Please install docker.)
endif

DOCKER_COMPOSE?=$(shell command -v docker-compose || which docker-compose 2>/dev/null)
DOCKER_COMPOSE_FLAGS?=
DOCKER_COMPOSE_UP_FLAGS?=--detach
DOCKER_COMPOSE_FILES?=compose.yaml compose.yml docker-compose.yaml docker-compose.yml
DOCKER_COMPOSE_DIRECTORY?=$(if $(wildcard $(DOCKER_COMPOSE_FILES)),.)
ifeq ($(DOCKER_COMPOSE),)
$(error Please install docker-compose.)
endif

###
## Docker
###

# Login to all DOCKER_REGISTRIES
docker.login:
	@$(foreach registry,$(DOCKER_REGISTRIES),docker login $(registry);)

#. Create a Docker network %
docker.network.%.create:
	@$(DOCKER) network create $(*) 2>/dev/null || true

###
## Compose
###

ifneq ($(DOCKER_COMPOSE_DIRECTORY),)

# Build the image(s)
compose.build:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) build --pull
.PHONY: compose.build

# Up the service(s)
compose.up:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up$(if $(DOCKER_COMPOSE_UP_FLAGS), $(DOCKER_COMPOSE_UP_FLAGS)) --remove-orphans
.PHONY: compose.up

# Follow the logs from the service(s)
compose.logs:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) logs --follow --tail="100"
.PHONY: compose.logs

# Down the service(s)
compose.down:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) down --remove-orphans
.PHONY: compose.down

# Kill the service(s)
compose.kill:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) kill
.PHONY: compose.kill

# Stop and remove the service(s) and their unnamed volume(s)
compose.clear:
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) down --remove-orphans --volumes --rmi all; \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) rm --stop --force -v
.PHONY: compose.clear

#. Ensure service % is running
compose.service.%.ensure-running:
	$(eval COMPOSE_RUNNING_CACHE=$(if $(COMPOSE_RUNNING_CACHE),$(COMPOSE_RUNNING_CACHE),$(shell $(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)"; )$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if ! echo "$(COMPOSE_RUNNING_CACHE)" | grep -q "$(*)" 2> /dev/null; then \
		$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
		$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up -d --remove-orphans $(*); \
		until $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running" | grep -q "$(*)" 2> /dev/null; do \
			if $(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=stopped" | grep -q "$(*)" 2> /dev/null; then \
				$(call println_in_style,The service "$(*)" stopped unexpectedly.); \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
	fi

#. Ensure service % is stopped
compose.service.%.ensure-stopped:
	$(eval COMPOSE_RUNNING_CACHE=$(if $(COMPOSE_RUNNING_CACHE),$(COMPOSE_RUNNING_CACHE),$(shell $(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)"; )$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if echo "$(COMPOSE_RUNNING_CACHE)" | grep -q "$(*)" 2> /dev/null; then \
		$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
		$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) stop $(*); \
	fi

# Open a shell in service %
compose.service.%.shell: compose.service.%.ensure-running
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec "$(*)" sh

#. Open a shell in service % (alias)
compose.service.%.sh: compose.service.%.shell
	@true

# Open a bash shell in service %
compose.service.%.bash: compose.service.%.ensure-running
	@$(if $(DOCKER_COMPOSE_DIRECTORY),cd "$(DOCKER_COMPOSE_DIRECTORY)";) \
	$(DOCKER_COMPOSE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) exec "$(*)" bash

endif
