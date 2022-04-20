###
##. Configuration
###

DOCKER_EXECUTABLE?=$(shell command -v docker || which docker 2>/dev/null || printf "%s" "docker")
DOCKER_SOCKET?=/var/run/docker.sock

DOCKER_COMPOSE_EXECUTABLE?=$(shell command -v docker-compose || which docker-compose 2>/dev/null || printf "%s" "docker-compose")
DOCKER_COMPOSE_EXTRA_FLAGS?=
DOCKER_COMPOSE_FLAGS?=$(if $(DOCKER_COMPOSE_EXTRA_FLAGS), $(DOCKER_COMPOSE_EXTRA_FLAGS))

###
## Docker
###

.PHONY: build up logs down remove

# Check if Docker is available, exit if it is not
$(DOCKER_EXECUTABLE):
	@if ! test -x "$$(@)"; then \
		printf "$$(STYLE_ERROR)%s$$(STYLE_RESET)\\n" "Could not run \"$$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

# Check if Docker-Compose is available, exit if it is not
$(DOCKER_COMPOSE_EXECUTABLE):
	@if ! test -x "$$(@)"; then \
		printf "$$(STYLE_ERROR)%s$$(STYLE_RESET)\\n" "Could not run \"$$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

RUNNING_CACHE=

#. Ensure container % is running
ensure-running-%: | $(DOCKER_COMPOSE_EXECUTABLE)
	$(eval RUNNING_CACHE=$(if $(RUNNING_CACHE),$(RUNNING_CACHE),$(shell $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if ! echo "$(RUNNING_CACHE)" | grep -q "$(*)" 2> /dev/null; then \
		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up -d --remove-orphans "$(*)"; \
		until $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running" | grep -q "$(*)" 2> /dev/null; do \
			if $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=stopped" | grep -q "$(*)" 2> /dev/null; then \
				$(call println_error,The image "$(*)" stopped unexpectedly.) \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
	fi

#. Ensure container % is not running
ensure-not-running-%: | $(DOCKER_COMPOSE_EXECUTABLE)
	$(eval RUNNING_CACHE=$(if $(RUNNING_CACHE),$(RUNNING_CACHE),$(shell $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if echo "$(RUNNING_CACHE)" | grep -q $(*) 2> /dev/null; then \
		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) stop $(*); \
	fi

#. Create a Docker network %
create-docker-network-%: | $(DOCKER_EXECUTABLE)
	@$(DOCKER_EXECUTABLE) network create $(*) 2>/dev/null || true

# Build the image
build: | $(DOCKER_COMPOSE_EXECUTABLE)
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) build

# Up the image
up: | $(DOCKER_COMPOSE_EXECUTABLE)
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up -d --remove-orphans

# Follow the logs
logs: | $(DOCKER_COMPOSE_EXECUTABLE)
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) logs --follow --tail="100"

# Down the image
down: | $(DOCKER_COMPOSE_EXECUTABLE)
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) down

# Stop the image
remove: | $(DOCKER_COMPOSE_EXECUTABLE)
	@if test -n "$$($(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --quiet --services --filter "status=running" 2> /dev/null)"; then \
  		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) rm --stop --force -v; \
	fi

# TODO # Clear all volumes
#clear-volumes: docker-compose.yaml docker-compose.dev.yaml | $(DOCKER_EXECUTABLE) stop
#	@if test -n "$$($(DOCKER_EXECUTABLE) volume ls --quiet --filter label=com.docker.compose.project=<PROJECT_NAME>)"; then \
#		$(DOCKER_EXECUTABLE) volume rm --force $$($(DOCKER_EXECUTABLE) volume ls --quiet --filter label=com.docker.compose.project=sqs-frontend); \
#	fi

###
## Docker Tools
###

.PHONY: ctop lazydocker

# Ctop - Real-time metrics for containers                      https://ctop.sh/
ctop: | $(DOCKER_EXECUTABLE)
	@set -e; \
		if test -z "$$($(DOCKER_EXECUTABLE) ps --quiet --filter="name=ctop")"; then \
			$(DOCKER_EXECUTABLE) run --rm --interactive --tty --name ctop \
				--volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
				quay.io/vektorlab/ctop:latest; \
		else \
			$(DOCKER_EXECUTABLE) attach ctop; \
		fi

# Lazydocker - Terminal UI          https://github.com/jesseduffield/lazydocker
lazydocker: | $(DOCKER_EXECUTABLE)
	@$(DOCKER_EXECUTABLE) run --rm --interactive --tty --volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
		--name lazydocker lazyteam/lazydocker:latest
