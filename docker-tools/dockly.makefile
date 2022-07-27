###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

#. Docker variables for dockly
DOCKLY_IMAGE?=lirantal/dockly:latest
DOCKLY_SERVICE_NAME?=dockly

###
## Docker Tools
###

# Run dockly in a container
# Immersive terminal interface for managing docker containers, services and images
# @see https://github.com/lirantal/dockly
dockly:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOCKLY_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DOCKLY_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(DOCKLY_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(DOCKLY_SERVICE_NAME)"; \
	fi
.PHONY: dockly
