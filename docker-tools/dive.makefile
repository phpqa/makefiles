###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

#. Docker variables for dive
DIVE_IMAGE?=wagoodman/dive:latest
DIVE_SERVICE_NAME_PREFIX?=dive-
DIVE_CONFIG?=$(firstword $(wildcard .dive.yaml .dive.yml))
DIVE_CI?=$(CI)

###
## Docker Tools
###

# Run dive in a container to inspect image %
# Exploring a docker image and its layer contents
# @see https://github.com/wagoodman/dive
dive-%: | $(DOCKER_DEPENDENCY)
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DIVE_SERVICE_NAME_PREFIX)$(subst :,-,$(*))" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DIVE_SERVICE_NAME_PREFIX)$(subst :,-,$(*))" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			$(if $(DIVE_CI),--env "CI=$(DIVE_CI)") \
			$(if $(DOCKER_API_VERSION),--env "DOCKER_API_VERSION=$(DOCKER_API_VERSION)") \
			"$(DIVE_IMAGE)" \
			"$(*)"; \
	else \
		$(DOCKER) container attach "$(DIVE_SERVICE_NAME_PREFIX)$(subst :,-,$(*))"; \
	fi
.PHONY: dive
