###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

#. Docker variables for Dozzle
DOZZLE_IMAGE?=amir20/dozzle:latest
DOZZLE_SERVICE_NAME?=dozzle

#. Overwrite the Dozzle defaults
DOZZLE_NO_ANALYTICS?=true

#. Support for all Dozzle variables
DOZZLE_VARIABLES_PREFIX?=DOZZLE_
DOZZLE_VARIABLES_EXCLUDED?=IMAGE SERVICE_NAME VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED TRAEFIK_DOMAIN TRAEFIK_NETWORK

#. Support for Traefik
DOZZLE_TRAEFIK_DOMAIN?=dozzle.localhost
DOZZLE_TRAEFIK_NETWORK?=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)

###
## Docker Tools
###

#. Pull the Dozzle container
dozzle.pull:%.pull:
	@$(DOCKER) image pull "$(DOZZLE_IMAGE)"
.PHONY: dozzle.pull

#. Start the Dozzle container
dozzle.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOZZLE_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --detach --name "$(DOZZLE_SERVICE_NAME)" \
			$(foreach variable,$(filter-out $(addprefix $(DOZZLE_VARIABLES_PREFIX),$(DOZZLE_VARIABLES_EXCLUDED)),$(filter $(DOZZLE_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(DOZZLE_VARIABLES_UNPREFIXED),$(patsubst $(DOZZLE_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(DOZZLE_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))") \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "8080" \
			$(if $(DOZZLE_TRAEFIK_NETWORK), \
				--label "traefik.enable=true" \
				--label "traefik.docker.network=$(DOZZLE_TRAEFIK_NETWORK)" \
				--label "traefik.http.routers.$(DOZZLE_SERVICE_NAME).entrypoints=web" \
				--label "traefik.http.routers.$(DOZZLE_SERVICE_NAME).rule=Host(\`$(DOZZLE_TRAEFIK_DOMAIN)\`)" \
				--label "traefik.http.services.$(DOZZLE_SERVICE_NAME).loadbalancer.server.port=8080" \
				--network "$(DOZZLE_TRAEFIK_NETWORK)" \
			) \
			"$(DOZZLE_IMAGE)" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(DOZZLE_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: dozzle.start

#. Wait for the Dozzle container to be running
dozzle.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(DOZZLE_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test -n "$$(curl -sSL --fail "http://$$($(DOCKER) container port "$(DOZZLE_SERVICE_NAME)" "8080" 2>/dev/null)" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(DOZZLE_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(DOZZLE_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: dozzle.ensure

#. List the url to the Dozzle container
dozzle.list:%.list: | %.ensure
	@printf "Open Dozzle: %s or %s\n" "http://$(DOZZLE_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" "http://$$($(DOCKER) container port "$(DOZZLE_SERVICE_NAME)" "8080")"
.PHONY: dozzle.list

#. List the logs of the Dozzle container
dozzle.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(DOZZLE_SERVICE_NAME)")" "$(DOZZLE_SERVICE_NAME)"
.PHONY: dozzle.log

#. Stop the Dozzle container
dozzle.stop:%.stop:
	@$(DOCKER) container stop "$(DOZZLE_SERVICE_NAME)"
.PHONY: dozzle.stop

#. Clear the Dozzle container
dozzle.clear:%.clear:
	@$(DOCKER) container kill "$(DOZZLE_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(DOZZLE_SERVICE_NAME)" &>/dev/null || true
.PHONY: dozzle.clear

#. Reset the Dozzle volume
dozzle.reset:%.reset:
	-@$(MAKE) $(*).clear
	@$(MAKE) $(*)
.PHONY: dozzle.reset

# Run Dozzle in a container
# @see https://github.com/amir20/dozzle
dozzle:%: | %.start %.list
	@true
.PHONY: dozzle
