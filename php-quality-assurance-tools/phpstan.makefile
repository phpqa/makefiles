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

PHPSTAN_CONFIG?=$(wildcard phpstan.neon)
PHPSTAN_BASELINE?=$(wildcard phpstan-baseline.neon)
PHPSTAN_DIRECTORIES_TO_CHECK?=$(if $(PHPSTAN_CONFIG),,.)
PHPSTAN_FLAGS?=
ifneq ($(wildcard $(PHPSTAN_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--configuration="$(PHPSTAN_CONFIG)"
endif
endif
PHPSTAN_MEMORY_LIMIT?=
ifneq ($(PHPSTAN_MEMORY_LIMIT),)
ifeq ($(findstring --memory-limit,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--memory-limit="$(PHPSTAN_MEMORY_LIMIT)"
endif
endif

###
## Quality Assurance Tools
###

#. Install PHPStan
vendor/bin/phpstan: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpstan/phpstan; fi

# Run PHPStan - Static Analysis Tool
# @see https://phpstan.org/
phpstan: $(wildcard $(PHPSTAN_CONFIG)) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) analyse$(if $(PHPSTAN_DIRECTORIES_TO_CHECK), $(PHPSTAN_DIRECTORIES_TO_CHECK))
.PHONY: phpstan

# Generate a baseline for PHPStan
phpstan-baseline.neon: | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) --generate-baseline$(if $(PHPSTAN_BASELINE),="$(PHPSTAN_BASELINE)")
