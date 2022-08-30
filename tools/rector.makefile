###
##. Configuration
###

#. Package variables
RECTOR_PACKAGE?=rector/rector
RECTOR?=$(PHP) vendor/bin/rector
ifeq ($(RECTOR),$(PHP) vendor/bin/rector)
RECTOR_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/rector
else
RECTOR_DEPENDENCY?=$(wildcard $(RECTOR))
endif
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=rector.dryrun
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY))
PHP_QUALITY_ASSURANCE_FIX_TOOLS+=rector
PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY)))

#. Tool variables
RECTOR_POSSIBLE_CONFIGS?=rector.php
RECTOR_CONFIG?=$(wildcard $(RECTOR_POSSIBLE_CONFIGS))

RECTOR_DIRECTORIES_TO_CHECK?=$(if $(RECTOR_CONFIG),,.)

RECTOR_MEMORY_LIMIT?=

#. Building the flags
RECTOR_FLAGS?=

ifneq ($(wildcard $(RECTOR_CONFIG)),)
ifeq ($(findstring --config,$(RECTOR_FLAGS)),)
RECTOR_FLAGS+=--config="$(RECTOR_CONFIG)"
endif
endif

ifneq ($(RECTOR_MEMORY_LIMIT),)
ifeq ($(findstring --memory-limit,$(RECTOR_FLAGS)),)
RECTOR_FLAGS+=--memory-limit="$(RECTOR_MEMORY_LIMIT)"
endif
endif

###
##. Requirements
###

ifeq ($(PHP),)
$(error The variable PHP should never be empty.)
endif
ifeq ($(PHP_DEPENDENCY),)
$(error The variable PHP_DEPENDENCY should never be empty.)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
$(error The variable COMPOSER_EXECUTABLE should never be empty.)
endif
ifeq ($(COMPOSER_DEPENDENCY),)
$(error The variable COMPOSER_DEPENDENCY should never be empty.)
endif
ifeq ($(RECTOR_PACKAGE),)
$(error The variable RECTOR_PACKAGE should never be empty.)
endif
ifeq ($(RECTOR),)
$(error The variable RECTOR should never be empty.)
endif
ifeq ($(RECTOR_DEPENDENCY),)
$(error The variable RECTOR_DEPENDENCY should never be empty.)
endif

###
## Quality Assurance
###

# Install Rector as dev dependency in vendor
vendor/bin/rector: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(RECTOR_PACKAGE)"; fi

#. Initialize Rector
rector.php: | $(RECTOR_DEPENDENCY)
	@$(RECTOR) init

# Run Rector #!
# @see https://github.com/rectorphp/rector
rector: | $(RECTOR_DEPENDENCY) rector.php
	@$(RECTOR)$(if $(RECTOR_FLAGS), $(RECTOR_FLAGS)) process $(RECTOR_DIRECTORIES_TO_CHECK)
.PHONY: rector

# Dryrun Rector
rector.dryrun: | $(RECTOR_DEPENDENCY) rector.php
	@$(RECTOR)$(if $(RECTOR_FLAGS), $(RECTOR_FLAGS)) --dry-run process $(RECTOR_DIRECTORIES_TO_CHECK)
.PHONY: rector.dryrun
