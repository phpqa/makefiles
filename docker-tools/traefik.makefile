###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

TRAEFIK_IMAGE?=traefik:latest
TRAEFIK_HTTP_PORT?=$(if $(PROJECT_PORT),$(PROJECT_PORT),80)

#. Overwrite the Traefik defaults
TRAEFIK_PROVIDERS_DOCKER?=true
TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT?=false
TRAEFIK_API_INSECURE?=true
TRAEFIK_ENTRYPOINTS_WEB_ADDRESS?=:$(TRAEFIK_HTTP_PORT)
TRAEFIK_PROVIDERS_DOCKER_NETWORK?=traefik

#. Support for all Traefik variables
TRAEFIK_VARIABLES_PREFIX?=TRAEFIK_
TRAEFIK_VARIABLES_EXCLUDED?=IMAGE HTTP_PORT VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED

###
## Docker Tools
###

#. Pull the Traefik container
traefik.pull:%.pull:
	@$(DOCKER) image pull "$(TRAEFIK_IMAGE)"
.PHONY: traefik.pull

#. Start the Traefik container
traefik.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(*)" 2> /dev/null)"; then \
		if test -z "$$($(DOCKER) network ls --quiet --filter "name=^$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)$$")"; then \
			$(DOCKER) network create "$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" &>/dev/null; \
		fi; \
		$(DOCKER) container run --detach --name "$(*)" \
			$(foreach variable,$(filter-out $(addprefix $(TRAEFIK_VARIABLES_PREFIX),$(TRAEFIK_VARIABLES_EXCLUDED)),$(filter $(TRAEFIK_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(TRAEFIK_VARIABLES_UNPREFIXED),$(patsubst $(TRAEFIK_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(TRAEFIK_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))") \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--label "com.centurylinklabs.traefik.enable=true" \
			--publish "$(TRAEFIK_HTTP_PORT):$(TRAEFIK_HTTP_PORT)" \
			--publish "8080" \
			$(if $(TRAEFIK_PROVIDERS_DOCKER_NETWORK), \
				--label "traefik.enable=true" \
				--label "traefik.docker.network=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" \
				--label "traefik.http.routers.$(*).entrypoints=web" \
				--label "traefik.http.routers.$(*).rule=Host(\`$(*).localhost\`)" \
				--label "traefik.http.services.$(*).loadbalancer.server.port=8080" \
				--network "$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)" \
			) \
			"$(TRAEFIK_IMAGE)"; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(*)" >/dev/null; \
		fi; \
		$(DOCKER) container inspect --format "{{ .ID }}" "$(*)"; \
	fi
.PHONY: traefik.start

#. Wait for the Traefik container to be running
traefik.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(*)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test -n "$$(curl -sSL --fail "http://$$($(DOCKER) container port "$(*)" "8080" 2>/dev/null)" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(*)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: traefik.ensure

#. List the url to the Traefik container
traefik.list:%.list: | %.ensure
	@printf "Open Traefik: %s\n" "http://$(*).localhost"
.PHONY: traefik.list

#. List the logs of the Traefik container
traefik.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"
.PHONY: traefik.log

#. Stop the Traefik container
traefik.stop:%.stop:
	@$(DOCKER) container stop "$(*)"
.PHONY: traefik.stop

#. Clear the Traefik container
traefik.clear:%.clear:
	@$(DOCKER) container kill "$(*)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(*)" &>/dev/null || true
	@$(DOCKER) network rm --force "$(*)" &>/dev/null || true
.PHONY: traefik.clear

#. Reset the Traefik volume
traefik.reset:%.reset:
	-@$(MAKE) $(*).clear
	@$(MAKE) $(*)
.PHONY: traefik.reset

# Run Traefik in a container
# @see https://doc.traefik.io/traefik/
traefik:%: | %.start %.list
	@true
.PHONY: traefik
