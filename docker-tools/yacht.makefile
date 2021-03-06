###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

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
## Docker Tools
###

#. Pull the Yacht container
yacht.pull:%.pull:
	@$(DOCKER) image pull "$(YACHT_IMAGE)"
.PHONY: yacht.pull

#. Start the Yacht container
yacht.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(YACHT_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --detach --name "$(YACHT_SERVICE_NAME)" \
			--env "DISABLE_AUTH=true" \
			--volume "$(YACHT_DATA_VOLUME):/config" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			$(if $(YACHT_PROJECTS_ROOT_DIR), \
				--env "COMPOSE_DIR=/compose/" \
				--volume "$(YACHT_PROJECTS_ROOT_DIR):/compose" \
			) \
			--publish "8000" \
			$(if $(YACHT_TRAEFIK_NETWORK), \
				--label "traefik.enable=true" \
				--label "traefik.docker.network=$(YACHT_TRAEFIK_NETWORK)" \
				--label "traefik.http.routers.$(YACHT_SERVICE_NAME).entrypoints=web" \
				--label "traefik.http.routers.$(YACHT_SERVICE_NAME).rule=Host(\`$(YACHT_TRAEFIK_DOMAIN)\`)" \
				--label "traefik.http.services.$(YACHT_SERVICE_NAME).loadbalancer.server.port=8000" \
				--network "$(YACHT_TRAEFIK_NETWORK)" \
			) \
			"$(YACHT_IMAGE)" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(YACHT_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: yacht.start

#. Wait for the Yacht container to be running
yacht.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(YACHT_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test -n "$$(curl -sSL --fail "http://$$($(DOCKER) container port "$(YACHT_SERVICE_NAME)" "8000" | grep "0.0.0.0" 2>/dev/null)" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(YACHT_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(YACHT_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: yacht.ensure

#. List the url to the Yacht container
yacht.list:%.list: | %.ensure
	@printf "Open Yacht: %s or %s\n" \
		"http://$(YACHT_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(YACHT_SERVICE_NAME)" "8000" | grep "0.0.0.0")"
.PHONY: yacht.list

#. List the logs of the Yacht container
yacht.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(YACHT_SERVICE_NAME)")" "$(YACHT_SERVICE_NAME)"
.PHONY: yacht.log

#. Stop the Yacht container
yacht.stop:%.stop:
	@$(DOCKER) container stop "$(YACHT_SERVICE_NAME)"
.PHONY: yacht.stop

#. Clear the Yacht container
yacht.clear:%.clear:
	@$(DOCKER) container kill "$(YACHT_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(YACHT_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) volume rm --force "$(YACHT_DATA_VOLUME)" &>/dev/null || true
.PHONY: yacht.clear

#. Reset the Yacht volume
yacht.reset:%.reset:
	-@$(MAKE) $(*).clear
	@$(MAKE) $(*)
.PHONY: yacht.reset

# Run Yacht in a container
# @see https://yacht.sh/
yacht:%: | %.start %.list
	@true
.PHONY: yacht
