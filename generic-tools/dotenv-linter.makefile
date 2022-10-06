###
##. Dependencies
###

ifeq ($(DOCKER),)
$(warning Please provide the variable DOCKER)
endif

###
##. Configuration
###

#. Image variables
DOTENV_LINTER_IMAGE?=dotenvlinter/dotenv-linter:latest
DOTENV_LINTER_SERVICE_NAME?=dotenv-linter

#. Tool variables
DOTENV_LINTER_COMMAND?=check

DOTENV_LINTER_CHECK_TARGETS?=$(if $(TARGET),$(TARGET),$(wildcard .env .env.*))
DOTENV_LINTER_FIX_TARGETS?=$(if $(TARGET),$(TARGET),$(wildcard .env .env.*))
DOTENV_LINTER_COMPARE_TARGETS?=$(if $(TARGET),$(TARGET),$(wildcard .env*.dist .env*.example))

#. Building the flags
DOTENV_LINTER_CHECK_CONTAINER_RUN_FLAGS?=
DOTENV_LINTER_CHECK_FLAGS?=--skip="UnorderedKey"

DOTENV_LINTER_FIX_CONTAINER_RUN_FLAGS?=
DOTENV_LINTER_FIX_FLAGS?=--skip="UnorderedKey"

DOTENV_LINTER_COMPARE_CONTAINER_RUN_FLAGS?=
DOTENV_LINTER_COMPARE_FLAGS?=

###
##. DotEnv Linter
##. Lightning-fast linter for .env files.
##. @see https://dotenv-linter.github.io/
###

# Run DotEnv Linter to check .env files
# @see https://dotenv-linter.github.io/
dotenv-linter.check:dotenv-linter.%: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER)
endif
ifeq ($(DOTENV_LINTER_CHECK_TARGETS),)
	$(error Please provide the variable DOTENV_LINTER_CHECK_TARGETS before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" \
			$(DOTENV_LINTER_CHECK_CONTAINER_RUN_FLAGS) $(foreach volume,$(DOTENV_LINTER_CHECK_TARGETS), --volume "$(realpath $(volume)):$(realpath $(volume))") "$(DOTENV_LINTER_IMAGE)" \
			check $(DOTENV_LINTER_CHECK_FLAGS) $(realpath $(DOTENV_LINTER_CHECK_TARGETS)); \
	fi
.PHONY: dotenv-linter.check
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=dotenv-linter.check

# Run DotEnv Linter to fix .env files
# @see https://dotenv-linter.github.io/
dotenv-linter.fix:dotenv-linter.%: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER)
endif
ifeq ($(DOTENV_LINTER_FIX_TARGETS),)
	$(error Please provide the variable DOTENV_LINTER_FIX_TARGETS before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" \
			$(DOTENV_LINTER_FIX_CONTAINER_RUN_FLAGS) $(foreach volume,$(DOTENV_LINTER_FIX_TARGETS), --volume "$(realpath $(volume)):$(realpath $(volume))") "$(DOTENV_LINTER_IMAGE)" \
			fix $(DOTENV_LINTER_FIX_FLAGS) $(realpath $(DOTENV_LINTER_FIX_TARGETS)); \
	fi
.PHONY: dotenv-linter.fix
PHP_QUALITY_ASSURANCE_FIX_TOOLS+=dotenv-linter.fix

# Run DotEnv Linter to compare .env files against *.dist or *.example
# @see https://dotenv-linter.github.io/
dotenv-linter.compare:dotenv-linter.%: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER)
endif
ifeq ($(DOTENV_LINTER_COMPARE_TARGETS),)
	$(error Please provide the variable DOTENV_LINTER_COMPARE_TARGETS before running $(@))
endif
	@$(foreach target,$(DOTENV_LINTER_COMPARE_TARGETS), \
	if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --interactive --tty --name "$(DOTENV_LINTER_SERVICE_NAME)-$(*)" \
			$(DOTENV_LINTER_COMPARE_CONTAINER_RUN_FLAGS) $(foreach volume,$(target) $(patsubst %.dist,%,$(patsubst %.example,%,$(target))), --volume "$(realpath $(volume)):$(realpath $(volume))") "$(DOTENV_LINTER_IMAGE)" \
			compare $(DOTENV_LINTER_COMPARE_FLAGS) $(realpath $(target)) $(realpath $(patsubst %.dist,%,$(patsubst %.example,%,$(target)))); \
	fi; \
	)
.PHONY: dotenv-linter.compare
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=dotenv-linter.compare
