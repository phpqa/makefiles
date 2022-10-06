###
##. Dependencies
###

ifeq ($(DOCKER),)
$(warning Please provide the variable DOCKER)
endif

###
##. Configuration
###

#. Docker variables
HADOLINT_IMAGE?=hadolint/hadolint:latest
HADOLINT_SERVICE_NAME?=hadolint-$(subst .,-,$(subst :,-,$(HADOLINT_TARGET)))

#. Configuration variables
HADOLINT_POSSIBLE_CONFIGS?=.hadolint.yaml $${XDG_CONFIG_HOME}/hadolint.yaml $${HOME}/.config/hadolint.yaml $${HOME}/.hadolint/hadolint.yaml $${HOME}/hadolint/config.yaml $${HOME}/.hadolint.yaml
HADOLINT_CONFIG?=$(firstword $(wildcard $(HADOLINT_POSSIBLE_CONFIGS)))

#. Adding our own variables
HADOLINT_TARGET?=$(if $(TARGET),$(TARGET),$(wildcard Dockerfile))
HADOLINT_NO_COLOR?=$(NO_COLOR)

#. Support for all variables
HADOLINT_VARIABLES_PREFIX?=HADOLINT_
HADOLINT_VARIABLES_EXCLUDED?=IMAGE SERVICE_NAME CONFIG CONTAINER_RUN_FLAGS FLAGS TARGET VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED
HADOLINT_VARIABLES_UNPREFIXED?=NO_COLOR

#. Building the flags
HADOLINT_CONTAINER_RUN_FLAGS?=
HADOLINT_FLAGS?=

ifneq ($(HADOLINT_CONFIG),)
HADOLINT_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(HADOLINT_CONFIG)):$(realpath $(HADOLINT_CONFIG))"
ifeq ($(findstring --config,$(HADOLINT_FLAGS)),)
HADOLINT_FLAGS+=--config "$(realpath $(HADOLINT_CONFIG))"
endif
endif

ifneq ($(HADOLINT_TARGET),)
ifneq ($(wildcard $(HADOLINT_TARGET)),)
HADOLINT_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(HADOLINT_TARGET)):$(realpath $(HADOLINT_TARGET))"
endif
endif

###
##. Hadolint
##. A smarter Dockerfile linter that helps you build best practice Docker images
##. @see https://github.com/hadolint/hadolint
###

# Run Hadolint in a container to inspect $HADOLINT_TARGET
# @see https://github.com/hadolint/hadolint
hadolint: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(HADOLINT_TARGET),)
	$(error Please provide the variable HADOLINT_TARGET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(HADOLINT_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(HADOLINT_SERVICE_NAME)" $(HADOLINT_CONTAINER_RUN_FLAGS) \
			"$(HADOLINT_IMAGE)" hadolint $(HADOLINT_FLAGS) "$(if $(wildcard $(HADOLINT_TARGET)),$(realpath $(HADOLINT_TARGET)),$(HADOLINT_TARGET))"; \
	fi
.PHONY: hadolint

#. Run Hadolint in a container to inspect the file $HADOLINT_TARGET
hadolint-file:
	HADOLINT_TARGET=$(HADOLINT_TARGET) hadolint
.PHONY: hadolint-file
