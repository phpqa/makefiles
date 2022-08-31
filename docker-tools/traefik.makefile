###
##. Configuration
###

#. Docker variables for Traefik
TRAEFIK_IMAGE?=traefik:latest
TRAEFIK_SERVICE_NAME?=traefik
TRAEFIK_DOMAIN?=traefik.localhost
TRAEFIK_HTTP_PORT?=$(if $(PROJECT_PORT),$(PROJECT_PORT),80)

#. Overwrite the Traefik defaults
TRAEFIK_PROVIDERS_DOCKER?=true
TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT?=false
TRAEFIK_API_INSECURE?=true
TRAEFIK_ENTRYPOINTS_WEB_ADDRESS?=:$(TRAEFIK_HTTP_PORT)
TRAEFIK_PROVIDERS_DOCKER_NETWORK?=traefik
TRAEFIK_PING?=true

#. Support for all Traefik variables
TRAEFIK_VARIABLES_PREFIX?=TRAEFIK_
TRAEFIK_VARIABLES_EXCLUDED?=IMAGE SERVICE_NAME DOMAIN HTTP_PORT VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED

###
##. Requirements
###

ifeq ($(DOCKER),)
$(error The variable DOCKER should never be empty.)
endif
ifeq ($(DOCKER_DEPENDENCY),)
$(error The variable DOCKER_DEPENDENCY should never be empty.)
endif
ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

###
## Docker Tools
###

#. Pull the Traefik container
traefik.pull:%.pull: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) image pull "$(TRAEFIK_IMAGE)"
.PHONY: traefik.pull

#. Start the Traefik container
traefik.start:%.start: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(TRAEFIK_SERVICE_NAME)" 2> /dev/null)"; then \
		if test -z "$$($(DOCKER) network ls --quiet --filter "name=^$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)$$")"; then \
			$(DOCKER) network create "$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" > /dev/null 2>&1; \
		fi; \
		$(DOCKER) container run --detach --name "$(TRAEFIK_SERVICE_NAME)" \
			$(foreach variable,$(filter-out $(addprefix $(TRAEFIK_VARIABLES_PREFIX),$(TRAEFIK_VARIABLES_EXCLUDED)),$(filter $(TRAEFIK_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(TRAEFIK_VARIABLES_UNPREFIXED),$(patsubst $(TRAEFIK_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(TRAEFIK_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))") \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--label "com.centurylinklabs.watchtower.enable=true" \
			--publish "$(TRAEFIK_HTTP_PORT):$(TRAEFIK_HTTP_PORT)" \
			--publish "8080" \
			--label "traefik.enable=true" \
			--label "traefik.docker.network=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" \
			--label "traefik.http.routers.$(TRAEFIK_SERVICE_NAME).entrypoints=web" \
			--label "traefik.http.routers.$(TRAEFIK_SERVICE_NAME).rule=Host(\`$(TRAEFIK_DOMAIN)\`)" \
			--label "traefik.http.services.$(TRAEFIK_SERVICE_NAME).loadbalancer.server.port=8080" \
			--network "$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" \
			"$(TRAEFIK_IMAGE)" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(TRAEFIK_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(TRAEFIK_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: traefik.start

#. Wait for the Traefik container to be running
traefik.ensure-running:%.ensure-running: | $(DOCKER_DEPENDENCY) %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(TRAEFIK_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(TRAEFIK_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(TRAEFIK_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(TRAEFIK_SERVICE_NAME)")" "$(TRAEFIK_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until $(DOCKER) container exec "$(TRAEFIK_SERVICE_NAME)" traefik healthcheck --ping > /dev/null 2>&1; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(TRAEFIK_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(TRAEFIK_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(TRAEFIK_SERVICE_NAME)")" "$(TRAEFIK_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: traefik.ensure-running

#. List the url to the Traefik container
traefik.list:%.list: | $(DOCKER_DEPENDENCY) %.ensure-running
	@printf "Open Traefik: %s or %s\n" \
		"http://$(TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(*)" "8080" | grep "0.0.0.0")"
.PHONY: traefik.list

#. List the logs of the Traefik container
traefik.log:%.log: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(TRAEFIK_SERVICE_NAME)")" "$(TRAEFIK_SERVICE_NAME)"
.PHONY: traefik.log

#. Stop the Traefik container
traefik.stop:%.stop: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container stop "$(TRAEFIK_SERVICE_NAME)"
.PHONY: traefik.stop

#. Clear the Traefik container
traefik.clear:%.clear: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container kill "$(TRAEFIK_SERVICE_NAME)" > /dev/null 2>&1 || true
	@$(DOCKER) container rm --force --volumes "$(TRAEFIK_SERVICE_NAME)" > /dev/null 2>&1 || true
	@$(DOCKER) network rm --force "$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" > /dev/null 2>&1 || true
.PHONY: traefik.clear

#. Wait for the Traefik container to be cleared
traefik.ensure-cleared:%.ensure-cleared: | $(DOCKER_DEPENDENCY) %.clear
	@until test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(TRAEFIK_SERVICE_NAME)$$")"; do \
		sleep 1; \
	done
.PHONY: traefik.ensure-cleared

#. Reset the Traefik volume
traefik.reset:%.reset: | %.ensure-cleared %.ensure-running; @true
.PHONY: traefik.reset

# Run Traefik in a container
# @see https://doc.traefik.io/traefik/
traefik:%: | %.start %.list; @true
.PHONY: traefik
