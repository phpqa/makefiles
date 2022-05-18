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

# Open ctop in a Docker container
# Concise commandline monitoring for containers
# @see https://ctop.sh/
ctop:
	@set -e; \
		if test -z "$$($(DOCKER) ps --quiet --filter="name=$(@)")"; then \
			$(DOCKER) run --rm --interactive --tty --name $(@) \
				--volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
				quay.io/vektorlab/ctop:latest; \
		else \
			$(DOCKER) attach $(@); \
		fi
.PHONY: ctop
