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
TRIVY_IMAGE?=aquasec/trivy:latest
TRIVY_SERVICE_NAME?=trivy-$(subst .,-,$(subst :,-,$(TRIVY_TARGET)))

#. Configuration variables
TRIVY_POSSIBLE_CONFIGS?=trivy.yaml trivy.yml
TRIVY_CONFIG?=$(firstword $(wildcard $(TRIVY_POSSIBLE_CONFIGS)))

#. Adding our own variables
TRIVY_TARGET?=$(TARGET)

#. Add repository tokens
TRIVY_GITHUB_TOKEN?=$(GITHUB_TOKEN)
TRIVY_GITLAB_TOKEN?=$(GITLAB_TOKEN)

#. Support for all variables
TRIVY_VARIABLES_PREFIX?=TRIVY_
TRIVY_VARIABLES_EXCLUDED?=IMAGE SERVICE_NAME CONFIG CONTAINER_RUN_FLAGS FLAGS TARGET_COMMAND TARGET CACHE_DIR VARIABLES_PREFIX VARIABLES_EXCLUDED VARIABLES_UNPREFIXED
TRIVY_VARIABLES_UNPREFIXED?=GITHUB_TOKEN GITLAB_TOKEN

#. Overwrite variables
TRIVY_CACHE_DIR?=$(wildcard .cache/trivy)

#. Building the flags
TRIVY_CONTAINER_RUN_FLAGS?=
TRIVY_FLAGS?=

ifneq ($(TRIVY_CONFIG),)
TRIVY_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(TRIVY_CONFIG)):$(realpath $(TRIVY_CONFIG))"
ifeq ($(findstring --config,$(TRIVY_FLAGS)),)
TRIVY_FLAGS+=--config "$(realpath $(TRIVY_CONFIG))"
endif
endif

TRIVY_CONTAINER_RUN_FLAGS+=$(foreach variable,$(filter-out $(addprefix $(TRIVY_VARIABLES_PREFIX),$(TRIVY_VARIABLES_EXCLUDED)),$(filter $(TRIVY_VARIABLES_PREFIX)%,$(.VARIABLES))),--env "$(if $(filter $(TRIVY_VARIABLES_UNPREFIXED),$(patsubst $(TRIVY_VARIABLES_PREFIX)%,%,$(variable))),$(patsubst $(TRIVY_VARIABLES_PREFIX)%,%,$(variable)),$(variable))=$($(variable))")

ifneq ($(TRIVY_TARGET),)
ifneq ($(wildcard $(TRIVY_TARGET)),)
TRIVY_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(TRIVY_TARGET)):$(realpath $(TRIVY_TARGET))"
TRIVY_TARGET_COMMAND?=$(if $(findstring .tar,$(suffix $(TRIVY_TARGET))),image --input,fs)
else
TRIVY_TARGET_COMMAND?=image
# TODO Provide a way to inspect a repository url, branch, commit or tag
endif
endif

ifneq ($(TRIVY_CACHE_DIR),)
ifneq ($(wildcard $(TRIVY_CACHE_DIR)),)
TRIVY_CONTAINER_RUN_FLAGS+=--volume "$(realpath $(TRIVY_CACHE_DIR)):$(realpath $(TRIVY_CACHE_DIR))"
TRIVY_CONTAINER_RUN_FLAGS+=--env "TRIVY_CACHE_DIR=$(realpath $(TRIVY_CACHE_DIR))"
else
TRIVY_CONTAINER_RUN_FLAGS+=--env "TRIVY_CACHE_DIR=$(TRIVY_CACHE_DIR)"
endif
endif

###
##. Trivy
##. Vulnerability/misconfiguration/secret scanner for containers and other artifacts
##. @see https://aquasecurity.github.io/trivy/v0.30.2/docs/
###

# Run Trivy in a container to inspect $TRIVY_TARGET
# @see https://aquasecurity.github.io/trivy/v0.30.2/docs/
trivy: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(TRIVY_TARGET),)
	$(error Please provide the variable TRIVY_TARGET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(TRIVY_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(TRIVY_SERVICE_NAME)" $(TRIVY_CONTAINER_RUN_FLAGS) \
			"$(TRIVY_IMAGE)" $(TRIVY_FLAGS) $(TRIVY_TARGET_COMMAND) "$(if $(wildcard $(TRIVY_TARGET)),$(realpath $(TRIVY_TARGET)),$(TRIVY_TARGET))"; \
	fi
.PHONY: trivy

#. Run Trivy in a container to inspect the image $TRIVY_TARGET
trivy-image: TRIVY_TARGET_COMMAND="image"
trivy-image: trivy; @true
.PHONY: trivy-image

#. Run Trivy in a container to inspect the image archive $TRIVY_TARGET
trivy-archive: TRIVY_TARGET_COMMAND="image --input"
trivy-archive: trivy; @true
.PHONY: trivy-archive

#. Run Trivy in a container to inspect the file $TRIVY_TARGET
trivy-file: TRIVY_TARGET_COMMAND="fs"
trivy-file: trivy; @true
.PHONY: trivy-file

#. Run Trivy in a container to inspect the directory $TRIVY_TARGET
trivy-directory: TRIVY_TARGET_COMMAND="fs"
trivy-directory: trivy; @true
.PHONY: trivy-directory
