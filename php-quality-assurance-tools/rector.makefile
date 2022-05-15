###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

RECTOR_DRYRUN?=$(PHP_QA_DRYRUN)

###
## Quality Assurance Tools
###

#. Install Rector
vendor/bin/rector: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev rector/rector; fi

#. Initialize Rector
rector.php: | $(PHP_DEPENDENCY) vendor/bin/rector
	@$(PHP) vendor/bin/rector init

# Run Rector - Instant Upgrades and Automated Refactoring
# @see https://github.com/rectorphp/rector
rector: | $(PHP_DEPENDENCY) vendor/bin/rector rector.php
	@$(PHP) vendor/bin/rector process$(if $(RECTOR_DRYRUN), --dry-run) .
.PHONY: rector
