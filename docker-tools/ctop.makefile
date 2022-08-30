###
##. Configuration
###

#. Docker variables for ctop
CTOP_IMAGE?=quay.io/vektorlab/ctop:latest
CTOP_SERVICE_NAME?=ctop

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

# Run ctop in a container
# Concise commandline monitoring for containers
# @see https://ctop.sh/
ctop: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(CTOP_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(CTOP_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(CTOP_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(CTOP_SERVICE_NAME)"; \
	fi
.PHONY: ctop
