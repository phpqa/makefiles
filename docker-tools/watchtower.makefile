###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

WATCHTOWER_IMAGE?=containrrr/watchtower:latest

#. Overwrite the Watchtower defaults
WATCHTOWER_TZ?=$(TZ)
WATCHTOWER_LABEL_ENABLE?=true

#. Support for all Watchtower variables
WATCHTOWER_VARIABLES_PREFIX?=WATCHTOWER_
WATCHTOWER_VARIABLES_EXCLUDED?=IMAGE VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED
WATCHTOWER_VARIABLES_UNPREFIXED?=TZ NO_COLOR DOCKER_HOST DOCKER_CONFIG DOCKER_API_VERSION DOCKER_TLS_VERIFY DOCKER_CERT_PATH

###
## Docker Tools
###

#. Pull the Watchtower container
watchtower.pull:%.pull:
	@$(DOCKER) image pull "$(WATCHTOWER_IMAGE)"
.PHONY: watchtower.pull

#. Start the Watchtower container
watchtower.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --detach --name "$(*)" \
			$(foreach variable,$(filter-out $(addprefix $(WATCHTOWER_VARIABLES_PREFIX),$(WATCHTOWER_VARIABLES_EXCLUDED)),$(filter $(WATCHTOWER_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(WATCHTOWER_VARIABLES_UNPREFIXED),$(patsubst $(WATCHTOWER_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(WATCHTOWER_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))") \
			$(if $(DOCKER_CONFIG),--volume "$(DOCKER_CONFIG):$(if $(WATCHTOWER_DOCKER_CONFIG),$(WATCHTOWER_DOCKER_CONFIG),/config.json):ro") \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--label "com.centurylinklabs.watchtower.enable=true" \
			"$(WATCHTOWER_IMAGE)"; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(*)" >/dev/null; \
		fi; \
		$(DOCKER) container inspect --format "{{ .ID }}" "$(*)"; \
	fi
.PHONY: watchtower.start

#. Wait for the Watchtower container to be running
watchtower.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(*)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(*)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: watchtower.ensure

#. List the logs of the Watchtower container
watchtower.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(*)")" "$(*)"
.PHONY: watchtower.log

#. Stop the Watchtower container
watchtower.stop:%.stop:
	@$(DOCKER) container stop "$(*)"
.PHONY: watchtower.stop

#. Clear the Watchtower container
watchtower.clear:%.clear:
	@$(DOCKER) container kill "$(*)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(*)" &>/dev/null || true
.PHONY: watchtower.clear

#. Reset the Watchtower volume
watchtower.reset:%.reset:
	-@$(MAKE) $(*).clear
	@$(MAKE) $(*)
.PHONY: watchtower.reset

# Run Watchtower in a container
# @see https://containrrr.dev/watchtower/
watchtower:%: | %.start
	@true
.PHONY: watchtower
