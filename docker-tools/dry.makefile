###
##. Configuration
###

#. Docker variables for dry
DRY_IMAGE?=moncho/dry:latest
DRY_SERVICE_NAME?=dry

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

# Run dry in a container
# A terminal application to manage Docker and Docker Swarm
# @see https://github.com/moncho/dry
dry: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DRY_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DRY_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(DRY_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(DRY_SERVICE_NAME)"; \
	fi
.PHONY: dry
