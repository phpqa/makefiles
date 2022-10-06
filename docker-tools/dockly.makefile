###
##. Dependencies
###

ifeq ($(DOCKER),)
$(warning Please provide the variable DOCKER)
endif
ifeq ($(DOCKER_SOCKET),)
$(warning Please provide the variable DOCKER_SOCKET)
endif

###
##. Configuration
###

#. Docker variables
DOCKLY_IMAGE?=lirantal/dockly:latest
DOCKLY_SERVICE_NAME?=dockly

###
##. dockly
##. Immersive terminal interface for managing docker containers, services and images
##. @see https://github.com/lirantal/dockly
###

# Run dockly in a container
# @see https://github.com/lirantal/dockly
dockly: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(DOCKER_SOCKET),)
	$(error Please provide the variable DOCKER_SOCKET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOCKLY_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DOCKLY_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(DOCKLY_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(DOCKLY_SERVICE_NAME)"; \
	fi
.PHONY: dockly
