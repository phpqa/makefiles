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
		if test -z "$$($(DOCKER) ps --quiet --filter="name=ctop")"; then \
			$(DOCKER) run --rm --interactive --tty --name ctop \
				--volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
				quay.io/vektorlab/ctop:latest; \
		else \
			$(DOCKER) attach ctop; \
		fi
.PHONY: ctop

# Open lazydocker in a Docker container
# A simple terminal UI for both docker and docker-compose
# @see https://github.com/jesseduffield/lazydocker
lazydocker:
	@$(DOCKER) run --rm --interactive --tty --volume $(DOCKER_SOCKET):$(DOCKER_SOCKET):ro \
		--name lazydocker lazyteam/lazydocker:latest
.PHONY: lazydocker
