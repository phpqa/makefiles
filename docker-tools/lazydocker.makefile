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

# Open lazydocker in a Docker container
# A simple terminal UI for both docker and docker-compose
# @see https://github.com/jesseduffield/lazydocker
lazydocker:
	@set -e; \
		if test -z "$$($(DOCKER) ps --quiet --filter="name=$(@)")"; then \
			$(DOCKER) run --rm --interactive --tty --name $(@) \
				--volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
				lazyteam/lazydocker:latest; \
		else \
			$(DOCKER) attach $(@); \
		fi
.PHONY: lazydocker
