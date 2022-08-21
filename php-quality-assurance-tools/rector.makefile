###
##. Dependencies
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

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

#. Configuration variables
RECTOR_POSSIBLE_CONFIGS?=rector.php
RECTOR_CONFIG?=$(wildcard $(RECTOR_POSSIBLE_CONFIGS))

#. Extra variables
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
## PHP Quality Assurance Tools
###

ifeq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY))),)

# Install Rector as dev dependency in vendor
vendor/bin/rector: | $(COMPOSER_DEPENDENCY) vendor
	@$(COMPOSER_EXECUTABLE) require --dev "$(RECTOR_PACKAGE)"

else

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

endif
