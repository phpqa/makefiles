###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PHPSTAN?=$(PHP) vendor/bin/phpstan
ifeq ($(PHPSTAN),$(PHP) vendor/bin/phpstan)
PHPSTAN_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpstan
else
PHPSTAN_DEPENDENCY?=$(wildcard $(PHPSTAN))
endif
PHPSTAN_FLAGS?=--memory-limit=-1
ifeq ($(findstring --no-interaction,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--no-interaction
endif

###
## Quality Assurance Tools
###

#. Install PHPStan
vendor/bin/phpstan: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpstan/phpstan; fi

# Run PHPStan - Static Analysis Tool
# @see https://github.com/phpstan/phpstan
phpstan: | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) analyse .
.PHONY: phpstan

# Generate a baseline for PHPStan
phpstan-baseline.neon: | $(PHP_DEPENDENCY) vendor/bin/phpstan
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) --generate-baseline
