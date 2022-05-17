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
RECTOR_FLAGS?=

###
## Quality Assurance Tools
###

#. Install Rector
vendor/bin/rector: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev rector/rector; fi

#. Initialize Rector
rector.php: | $(RECTOR_DEPENDENCY)
	@$(RECTOR) init

# Run Rector - Instant Upgrades and Automated Refactoring
# @see https://github.com/rectorphp/rector
rector: | $(RECTOR_DEPENDENCY) rector.php
	@$(RECTOR)$(if $(RECTOR_FLAGS), $(RECTOR_FLAGS)) process .
.PHONY: rector