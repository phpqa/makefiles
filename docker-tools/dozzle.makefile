###
##. Dependencies
###

CURL?=$(shell command -v curl || which curl 2>/dev/null)
ifeq ($(CURL),)
CURL?=$(DOCKER) run --rm --network host curlimages/curl:latest
endif

###
##. Configuration
###

#. Docker variables for Dozzle
DOZZLE_IMAGE?=amir20/dozzle:latest
DOZZLE_SERVICE_NAME?=dozzle

#. Overwrite the Dozzle defaults
DOZZLE_NO_ANALYTICS?=true

#. Support for all Dozzle variables
DOZZLE_VARIABLES_PREFIX?=DOZZLE_
DOZZLE_VARIABLES_EXCLUDED?=IMAGE SERVICE_NAME VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED TRAEFIK_DOMAIN TRAEFIK_NETWORK

#. Support for Traefik
DOZZLE_TRAEFIK_DOMAIN?=$(DOZZLE_SERVICE_NAME).localhost
DOZZLE_TRAEFIK_NETWORK?=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)

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

#. Pull the Dozzle container
dozzle.pull:%.pull: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) image pull "$(DOZZLE_IMAGE)"
.PHONY: dozzle.pull

#. Start the Dozzle container
dozzle.start:%.start: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOZZLE_SERVICE_NAME)" 2> /dev/null)"; then \
		if test -z "$$($(DOCKER) network ls --quiet --filter "name=^$(DOZZLE_TRAEFIK_NETWORK)$$")"; then \
			$(DOCKER) network create "$(DOZZLE_TRAEFIK_NETWORK)" > /dev/null 2>&1; \
		fi; \
		$(DOCKER) container run --detach --name "$(DOZZLE_SERVICE_NAME)" \
			$(foreach variable,$(filter-out $(addprefix $(DOZZLE_VARIABLES_PREFIX),$(DOZZLE_VARIABLES_EXCLUDED)),$(filter $(DOZZLE_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(DOZZLE_VARIABLES_UNPREFIXED),$(patsubst $(DOZZLE_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(DOZZLE_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))") \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "8080" \
			--label "traefik.enable=true" \
			$(if $(DOZZLE_TRAEFIK_NETWORK),--label "traefik.docker.network=$(DOZZLE_TRAEFIK_NETWORK)") \
			--label "traefik.http.routers.$(DOZZLE_SERVICE_NAME).entrypoints=web" \
			--label "traefik.http.routers.$(DOZZLE_SERVICE_NAME).rule=Host(\`$(DOZZLE_TRAEFIK_DOMAIN)\`)" \
			--label "traefik.http.services.$(DOZZLE_SERVICE_NAME).loadbalancer.server.port=8080" \
			$(if $(DOZZLE_TRAEFIK_NETWORK),--network "$(DOZZLE_TRAEFIK_NETWORK)") \
			"$(DOZZLE_IMAGE)" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(DOZZLE_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: dozzle.start

#. Wait for the Dozzle container to be running
dozzle.ensure-running:%.ensure-running: | $(DOCKER_DEPENDENCY) %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(DOZZLE_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test "$$($(CURL) --location --silent --fail --output /dev/null --write-out "%{http_code}" "http://$$($(DOCKER) container port "$(DOZZLE_SERVICE_NAME)" "8080" 2>/dev/null | grep "0.0.0.0")")" = "200"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "health=healthy" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(DOZZLE_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: dozzle.ensure-running

#. List the url to the Dozzle container
dozzle.list:%.list: | $(DOCKER_DEPENDENCY) %.ensure-running
	@printf "Open Dozzle: %s or %s\n" \
		"http://$(DOZZLE_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(DOZZLE_SERVICE_NAME)" "8080" | grep "0.0.0.0")"
.PHONY: dozzle.list

#. List the logs of the Dozzle container
dozzle.log:%.log: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"
.PHONY: dozzle.log

#. Stop the Dozzle container
dozzle.stop:%.stop: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container stop "$(DOZZLE_SERVICE_NAME)"
.PHONY: dozzle.stop

#. Clear the Dozzle container
dozzle.clear:%.clear: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container kill "$(DOZZLE_SERVICE_NAME)" > /dev/null 2>&1|| true
	@$(DOCKER) container rm --force --volumes "$(DOZZLE_SERVICE_NAME)" > /dev/null 2>&1 || true
.PHONY: dozzle.clear

#. Wait for the Dozzle container to be cleared
dozzle.ensure-cleared:%.ensure-cleared: | $(DOCKER_DEPENDENCY) %.clear
	@until test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$")"; do \
		sleep 1; \
	done
.PHONY: dozzle.ensure-cleared

#. Reset the Dozzle volume
dozzle.reset:%.reset: | %.ensure-cleared %.ensure-running; @true
.PHONY: dozzle.reset

# Run Dozzle in a container
# @see https://github.com/amir20/dozzle
dozzle:%: | %.start %.list;           @true
.PHONY: dozzle
