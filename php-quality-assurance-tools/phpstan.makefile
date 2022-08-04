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
PHPSTAN_PACKAGE?=phpstan/phpstan
PHPSTAN?=$(PHP) vendor/bin/phpstan
ifeq ($(PHPSTAN),$(PHP) vendor/bin/phpstan)
PHPSTAN_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpstan
else
PHPSTAN_DEPENDENCY?=$(wildcard $(PHPSTAN))
endif

#. Configuration variables
PHPSTAN_POSSIBLE_CONFIGS?=phpstan.neon phpstan.neon.dist phpstan.dist.neon
PHPSTAN_CONFIG?=$(firstword $(wildcard $(PHPSTAN_POSSIBLE_CONFIGS)))

#. Extra variables
PHPSTAN_BASELINE?=$(wildcard phpstan-baseline.neon)
PHPSTAN_DIRECTORIES_TO_CHECK?=$(if $(PHPSTAN_CONFIG),,$(if $(wildcard src),src,.))
PHPSTAN_MEMORY_LIMIT?=

#. Building the flags
PHPSTAN_FLAGS?=
PHPSTAN_CLEAR_CACHE_FLAGS?=

ifneq ($(wildcard $(PHPSTAN_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--configuration="$(PHPSTAN_CONFIG)"
endif
endif

ifneq ($(wildcard $(PHPSTAN_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPSTAN_CLEAR_CACHE_FLAGS)),)
PHPSTAN_CLEAR_CACHE_FLAGS+=--configuration="$(PHPSTAN_CONFIG)"
endif
endif

ifneq ($(PHPSTAN_MEMORY_LIMIT),)
ifeq ($(findstring --memory-limit,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--memory-limit="$(PHPSTAN_MEMORY_LIMIT)"
endif
endif

###
## PHP Quality Assurance Tools
###

ifeq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPSTAN_DEPENDENCY))),)

# Install PHPStan as dev dependency in vendor
vendor/bin/phpstan: | $(COMPOSER_DEPENDENCY) vendor
	@$(COMPOSER_EXECUTABLE) require --dev "$(PHPSTAN_PACKAGE)"

else

# Run PHPStan
# @see https://phpstan.org/
phpstan: $(wildcard $(PHPSTAN_CONFIG)) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) analyse$(if $(PHPSTAN_DIRECTORIES_TO_CHECK), $(PHPSTAN_DIRECTORIES_TO_CHECK))
.PHONY: phpstan

# Generate a baseline for PHPStan
phpstan-baseline.neon: | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) --generate-baseline$(if $(PHPSTAN_BASELINE),="$(PHPSTAN_BASELINE)")
.PRECIOUS: phpstan-baseline.neon

# Clear the PHPStan cache
phpstan.clear-cache:: $(wildcard $(PHPSTAN_CONFIG)) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_CLEAR_CACHE_FLAGS), $(PHPSTAN_CLEAR_CACHE_FLAGS)) clear-result-cache
.PHONY: phpstan.clear-cache

endif
