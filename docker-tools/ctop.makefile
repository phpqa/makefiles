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
CTOP_IMAGE?=quay.io/vektorlab/ctop:latest
CTOP_SERVICE_NAME?=ctop

###
##. ctop
##. Concise commandline monitoring for containers
##. @see https://ctop.sh/
###

# Run ctop in a container
# @see https://ctop.sh/
ctop: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(DOCKER_SOCKET),)
	$(error Please provide the variable DOCKER_SOCKET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(CTOP_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(CTOP_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(CTOP_IMAGE)"; \
	else \
		$(DOCKER) container attach "$(CTOP_SERVICE_NAME)"; \
	fi
.PHONY: ctop
