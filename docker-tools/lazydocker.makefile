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
LAZYDOCKER_IMAGE?=lazyteam/lazydocker:latest
LAZYDOCKER_SERVICE_NAME?=lazydocker

###
##. lazydocker
##. A simple terminal UI for both docker and docker-compose
##. @see https://github.com/jesseduffield/lazydocker
###

# Run lazydocker in a container
# @see https://github.com/jesseduffield/lazydocker
lazydocker:| $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(DOCKER_SOCKET),)
	$(error Please provide the variable DOCKER_SOCKET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(LAZYDOCKER_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(LAZYDOCKER_SERVICE_NAME)" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			"$(LAZYDOCKER_IMAGE)"; \
	else \
		$(DOCKER) attach $(LAZYDOCKER_SERVICE_NAME); \
	fi
.PHONY: lazydocker
