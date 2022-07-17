###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

#. Docker variables for lazydocker
LAZYDOCKER_IMAGE?=lazyteam/lazydocker:latest
LAZYDOCKER_SERVICE_NAME?=lazydocker

###
## Docker Tools
###

# Run lazydocker in a container
# A simple terminal UI for both docker and docker-compose
# @see https://github.com/jesseduffield/lazydocker
lazydocker:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(LAZYDOCKER_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(LAZYDOCKER_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(LAZYDOCKER_IMAGE)"; \
	else \
		$(DOCKER) attach $(LAZYDOCKER_SERVICE_NAME); \
	fi
.PHONY: lazydocker
