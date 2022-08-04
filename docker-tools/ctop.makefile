###
##. Dependencies
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

###
##. Configuration
###

#. Docker variables for ctop
CTOP_IMAGE?=quay.io/vektorlab/ctop:latest
CTOP_SERVICE_NAME?=ctop

###
## Docker Tools
###

# Run ctop in a container
# Concise commandline monitoring for containers
# @see https://ctop.sh/
ctop:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(CTOP_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(CTOP_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(CTOP_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(CTOP_SERVICE_NAME)"; \
	fi
.PHONY: ctop
