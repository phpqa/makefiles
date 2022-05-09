###
##. Configuration
###

DOCKER_SOCKET?=/var/run/docker.sock

DOCKER_EXECUTABLE?=$(shell command -v docker || which docker 2>/dev/null)

DOCKER_COMPOSE_EXECUTABLE?=$(shell command -v docker-compose || which docker-compose 2>/dev/null)
DOCKER_COMPOSE_EXTRA_FLAGS?=
DOCKER_COMPOSE_FLAGS?=$(if $(DOCKER_COMPOSE_EXTRA_FLAGS), $(DOCKER_COMPOSE_EXTRA_FLAGS))

###
## Docker
###

.PHONY: docker docker-compose build up logs down remove

#. Check if Docker is available, exit if it is not
docker:
	@if test -z "$(DOCKER_EXECUTABLE)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not run \"$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

#. Check if Docker-Compose is available, exit if it is not
docker-compose:
	@if test -z "$(DOCKER_COMPOSE_EXECUTABLE)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not run \"$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

RUNNING_CACHE=

#. Ensure container % is running
ensure-running-%: | docker-compose
	$(eval RUNNING_CACHE=$(if $(RUNNING_CACHE),$(RUNNING_CACHE),$(shell $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if ! echo "$(RUNNING_CACHE)" | grep -q "$(*)" 2> /dev/null; then \
		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up -d --remove-orphans "$(*)"; \
		until $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running" | grep -q "$(*)" 2> /dev/null; do \
			if $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=stopped" | grep -q "$(*)" 2> /dev/null; then \
				$(call println_error,The image "$(*)" stopped unexpectedly.); \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
	fi

#. Ensure container % is not running
ensure-not-running-%: | docker-compose
	$(eval RUNNING_CACHE=$(if $(RUNNING_CACHE),$(RUNNING_CACHE),$(shell $(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running")))
	@if echo "$(RUNNING_CACHE)" | grep -q $(*) 2> /dev/null; then \
		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) stop $(*); \
	fi

#. Create a Docker network %
create-docker-network-%: | docker
	@$(DOCKER_EXECUTABLE) network create $(*) 2>/dev/null || true

# Build the image(s)
build: | docker-compose
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) build

# Up the service(s)
up: | docker-compose
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) up -d --remove-orphans

# Follow the logs from the service(s)
logs: | docker-compose
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) logs --follow --tail="100"

# Down the service(s)
down: | docker-compose
	@$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) down

# Stop and remove the service(s) and volume(s)
remove: | docker-compose
	@if test -n "$$($(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) ps --services --filter "status=running" 2> /dev/null)"; then \
  		$(DOCKER_COMPOSE_EXECUTABLE)$(if $(DOCKER_COMPOSE_FLAGS), $(DOCKER_COMPOSE_FLAGS)) rm --stop --force -v; \
	fi

# TODO # Clear all volumes
#clear-volumes: docker-compose.yaml docker-compose.dev.yaml | $(DOCKER_DEPENDENCY) stop
#	@if test -n "$$($(DOCKER_EXECUTABLE) volume ls --quiet --filter label=com.docker.compose.project=<PROJECT_NAME>)"; then \
#		$(DOCKER_EXECUTABLE) volume rm --force $$($(DOCKER_EXECUTABLE) volume ls --quiet --filter label=com.docker.compose.project=sqs-frontend); \
#	fi
