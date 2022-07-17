###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

YACHT_IMAGE?=selfhostedpro/yacht:latest
YACHT_DATA_VOLUME?=yacht_data
YACHT_HTTP_PORT?=8000

YACHT_PROJECTS_ROOT_DIR?=

YACHT_TRAEFIK_NETWORK?=$(TRAEFIK_NETWORK)

###
## Docker Tools
###

#. Pull the Yacht container
yacht.pull:%.pull:
	@$(DOCKER) image pull "$(YACHT_IMAGE)"
.PHONY: yacht.pull

#. Start the Yacht container
yacht.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --detach --name "$(*)" \
			--env "DISABLE_AUTH=true" \
			--volume "$(YACHT_DATA_VOLUME):/config" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			$(if $(YACHT_PROJECTS_ROOT_DIR), \
				--env "COMPOSE_DIR=/compose/" \
				--volume "$(YACHT_PROJECTS_ROOT_DIR):/compose" \
			) \
			--publish "$(YACHT_HTTP_PORT)" \
			$(if $(YACHT_TRAEFIK_NETWORK), \
				--label "traefik.enable=true" \
				--label "traefik.docker.network=$(YACHT_TRAEFIK_NETWORK)" \
				--label "traefik.http.routers.$(*).entrypoints=web" \
				--label "traefik.http.routers.$(*).rule=Host(\`$(*).localhost\`)" \
				--label "traefik.http.services.$(*).loadbalancer.server.port=$(YACHT_HTTP_PORT)" \
				--network "$(YACHT_TRAEFIK_NETWORK)" \
			) \
			"$(YACHT_IMAGE)"; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(*)" >/dev/null; \
		fi; \
		$(DOCKER) container inspect --format "{{ .ID }}" "$(*)"; \
	fi
.PHONY: yacht.start

#. Wait for the Yacht container to be running
yacht.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(*)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test -n "$$(curl -sSL --fail "http://$$($(DOCKER) container port "$(*)" "$(YACHT_HTTP_PORT)" 2>/dev/null)" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(*)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: yacht.ensure

#. List the url to the Yacht container
yacht.list:%.list: | %.ensure
	@printf "Open Yacht: http://$$($(DOCKER) container port "$(*)" "$(YACHT_HTTP_PORT)")" # TODO
.PHONY: yacht.list

#. List the logs of the Yacht container
yacht.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"
.PHONY: yacht.log

#. Stop the Yacht container
yacht.stop:%.stop:
	@$(DOCKER) container stop "$(*)"
.PHONY: yacht.stop

#. Clear the Yacht container
yacht.clear:%.clear:
	@$(DOCKER) container kill "$(*)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(*)" &>/dev/null || true
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
