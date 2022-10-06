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
DRY_IMAGE?=moncho/dry:latest
DRY_SERVICE_NAME?=dry

###
##. dry
##. A terminal application to manage Docker and Docker Swarm
##. @see https://github.com/moncho/dry
###

# Run dry in a container
# @see https://github.com/moncho/dry
dry: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(DOCKER_SOCKET),)
	$(error Please provide the variable DOCKER_SOCKET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DRY_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DRY_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(DRY_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(DRY_SERVICE_NAME)"; \
	fi
.PHONY: dry
