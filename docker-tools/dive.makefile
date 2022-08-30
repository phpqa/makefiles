###
##. Configuration
###

#. Docker variables for dive
DIVE_IMAGE?=wagoodman/dive:latest
DIVE_SERVICE_NAME?=dive-$(subst .,-,$(subst :,-,$(DIVE_TARGET)))

#. Configuration variables
DIVE_POSSIBLE_CONFIGS?=.dive.yaml .dive.yml
DIVE_CONFIG?=$(firstword $(wildcard $(DIVE_POSSIBLE_CONFIGS)))

#. Adding our own dive variables
DIVE_SOURCE?=$(if $(wildcard $(DIVE_TARGET)),docker-archive)
DIVE_TARGET?=$(TARGET)
DIVE_CI?=$(CI)

#. Building the flags
DIVE_CONTAINER_RUN_FLAGS?=
DIVE_FLAGS?=

ifneq ($(DOCKER_SOCKET),)
DIVE_CONTAINER_RUN_FLAGS+=--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro"
endif

ifneq ($(wildcard $(DIVE_CONFIG)),)
DIVE_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(DIVE_CONFIG))":"/root/.dive.yaml"
endif

ifneq ($(DIVE_CI),)
DIVE_CONTAINER_RUN_FLAGS+=--env "CI=$(DIVE_CI)"
endif

ifneq ($(DOCKER_API_VERSION),)
DIVE_CONTAINER_RUN_FLAGS+=--env "DOCKER_API_VERSION=$(DOCKER_API_VERSION)"
endif

ifneq ($(DIVE_SOURCE),)
ifeq ($(findstring --source,$(DIVE_FLAGS)),)
DIVE_FLAGS+=--source "$(DIVE_SOURCE)"
endif
endif

ifneq ($(wildcard $(DIVE_TARGET)),)
DIVE_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(DIVE_TARGET)):$(realpath $(DIVE_TARGET))"
ifeq ($(findstring --source,$(DIVE_FLAGS)),)
DIVE_FLAGS+=--source "docker-archive"
endif
endif

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

# Run dive in a container to inspect $DIVE_TARGET
# Exploring a docker image and its layer contents
# @see https://github.com/wagoodman/dive
dive: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DIVE_TARGET),)
	$(error Please provide the variable DIVE_TARGET before running dive.)
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DIVE_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DIVE_SERVICE_NAME)" $(DIVE_CONTAINER_RUN_FLAGS) \
			"$(DIVE_IMAGE)" $(DIVE_FLAGS) "$(if $(wildcard $(DIVE_TARGET)),$(realpath $(DIVE_TARGET)),$(DIVE_TARGET))"; \
	else \
		$(DOCKER) container attach "$(DIVE_SERVICE_NAME)"; \
	fi
.PHONY: dive

#. Run dive in a container to inspect the image $DIVE_TARGET
dive-image:
	@DIVE_TARGET="$(DIVE_TARGET)" $(MAKE) dive
.PHONY: dive-image

#. Run dive in a container to inspect the image archive $DIVE_TARGET
dive-archive:
	@DIVE_TARGET="$(DIVE_TARGET)" DIVE_SOURCE="docker-archive" $(MAKE) dive
.PHONY: dive-archive
