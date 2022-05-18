###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

RECTOR?=$(PHP) vendor/bin/rector
ifeq ($(RECTOR),$(PHP) vendor/bin/rector)
RECTOR_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/rector
else
RECTOR_DEPENDENCY?=$(wildcard $(RECTOR))
endif

RECTOR_CONFIG?=$(wildcard rector.php)
RECTOR_DIRECTORIES_TO_CHECK?=$(if $(RECTOR_CONFIG),,src)
RECTOR_FLAGS?=
ifneq ($(wildcard $(RECTOR_CONFIG)),)
ifeq ($(findstring --config,$(RECTOR_FLAGS)),)
RECTOR_FLAGS+=--config="$(RECTOR_CONFIG)"
endif
endif

###
## PHP Quality Assurance Tools
###

#. Install Rector
vendor/bin/rector: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev rector/rector; fi

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
