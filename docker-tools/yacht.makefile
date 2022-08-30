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

#. Docker variables for Yacht
YACHT_IMAGE?=selfhostedpro/yacht:latest
YACHT_SERVICE_NAME?=yacht
YACHT_DATA_VOLUME?=yacht_data

#. Extra variables for Yacht
YACHT_PROJECTS_ROOT_DIR?=

#. Support for Traefik
YACHT_TRAEFIK_DOMAIN?=$(YACHT_SERVICE_NAME).localhost
YACHT_TRAEFIK_NETWORK?=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)

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

#. Pull the Yacht container
yacht.pull:%.pull: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) image pull "$(YACHT_IMAGE)"
.PHONY: yacht.pull

#. Start the Yacht container
yacht.start:%.start: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(YACHT_SERVICE_NAME)" 2> /dev/null)"; then \
		if test -z "$$($(DOCKER) network ls --quiet --filter "name=^$(YACHT_TRAEFIK_NETWORK)$$")"; then \
			$(DOCKER) network create "$(YACHT_TRAEFIK_NETWORK)" &>/dev/null; \
		fi; \
		$(DOCKER) container run --detach --name "$(YACHT_SERVICE_NAME)" \
			--env "DISABLE_AUTH=true" \
			$(if $(YACHT_PROJECTS_ROOT_DIR),--env "COMPOSE_DIR=/compose/") \
			--volume "$(YACHT_DATA_VOLUME):/config" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			$(if $(YACHT_PROJECTS_ROOT_DIR),--volume "$(YACHT_PROJECTS_ROOT_DIR):/compose") \
			--publish "8000" \
			--label "traefik.enable=true" \
			$(if $(YACHT_TRAEFIK_NETWORK),--label "traefik.docker.network=$(YACHT_TRAEFIK_NETWORK)") \
			--label "traefik.http.routers.$(YACHT_SERVICE_NAME).entrypoints=web" \
			--label "traefik.http.routers.$(YACHT_SERVICE_NAME).rule=Host(\`$(YACHT_TRAEFIK_DOMAIN)\`)" \
			--label "traefik.http.services.$(YACHT_SERVICE_NAME).loadbalancer.server.port=8000" \
			$(if $(YACHT_TRAEFIK_NETWORK),--network "$(YACHT_TRAEFIK_NETWORK)") \
			"$(YACHT_IMAGE)" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(YACHT_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: yacht.start

#. Wait for the Yacht container to be running
yacht.ensure-running:%.ensure-running: | $(DOCKER_DEPENDENCY) %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(YACHT_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test "$$($(CURL) --location --silent --fail --output /dev/null --write-out "%{http_code}" "http://$$($(DOCKER) container port "$(YACHT_SERVICE_NAME)" "8000" 2>/dev/null | grep "0.0.0.0")")" = "200"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(YACHT_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: yacht.ensure-running

#. List the url to the Yacht container
yacht.list:%.list: | $(DOCKER_DEPENDENCY) %.ensure-running
	@printf "Open Yacht: %s or %s\n" \
		"http://$(YACHT_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(YACHT_SERVICE_NAME)" "8000" | grep "0.0.0.0")"
.PHONY: yacht.list

#. List the logs of the Yacht container
yacht.log:%.log: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"
.PHONY: yacht.log

#. Stop the Yacht container
yacht.stop:%.stop: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container stop "$(YACHT_SERVICE_NAME)"
.PHONY: yacht.stop

#. Clear the Yacht container
yacht.clear:%.clear: | $(DOCKER_DEPENDENCY)
	@$(DOCKER) container kill "$(YACHT_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(YACHT_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) volume rm --force "$(YACHT_DATA_VOLUME)" &>/dev/null || true
.PHONY: yacht.clear

#. Wait for the Yacht container to be cleared
yacht.ensure-cleared:%.ensure-cleared: | $(DOCKER_DEPENDENCY) %.clear
	@until test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$")"; do \
		sleep 1; \
	done
.PHONY: yacht.ensure-cleared

#. Reset the Yacht volume
yacht.reset:%.reset: | %.ensure-cleared %.ensure-running; @true
.PHONY: yacht.reset

# Run Yacht in a container
# @see https://yacht.sh/
yacht:%: | %.start %.list; @true
.PHONY: yacht
