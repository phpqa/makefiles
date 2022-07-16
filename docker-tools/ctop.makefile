###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

###
## Docker Tools
###

# Run ctop in a container
# Concise commandline monitoring for containers
# @see https://ctop.sh/
ctop:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(@)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name $(@) \
			--volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
			quay.io/vektorlab/ctop:latest; \
	else \
		$(DOCKER) attach $(@); \
	fi
.PHONY: ctop
