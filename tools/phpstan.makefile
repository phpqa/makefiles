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
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=phpstan
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPSTAN_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPSTAN_DEPENDENCY)))

#. Tool variables
PHPSTAN_POSSIBLE_CONFIGS?=phpstan.neon phpstan.neon.dist phpstan.dist.neon
PHPSTAN_CONFIG?=$(firstword $(wildcard $(PHPSTAN_POSSIBLE_CONFIGS)))

PHPSTAN_POSSIBLE_BASELINES?=phpstan-baseline.neon
PHPSTAN_BASELINE?=$(firstword $(wildcard $(PHPSTAN_POSSIBLE_BASELINES)))

PHPSTAN_DIRECTORIES_TO_CHECK?=$(if $(PHPSTAN_CONFIG),,.)

PHPSTAN_MEMORY_LIMIT?=

#. Building the flags
PHPSTAN_FLAGS?=
PHPSTAN_BASELINE_FLAGS?=
PHPSTAN_CLEAR_CACHE_FLAGS?=

ifneq ($(wildcard $(PHPSTAN_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPSTAN_FLAGS)),)
PHPSTAN_FLAGS+=--configuration="$(PHPSTAN_CONFIG)"
endif
ifeq ($(findstring --configuration,$(PHPSTAN_BASELINE_FLAGS)),)
PHPSTAN_BASELINE_FLAGS+=--configuration="$(PHPSTAN_CONFIG)"
endif
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
## Quality Assurance
###

# Install PHPStan as dev dependency in vendor
vendor/bin/phpstan: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PHPSTAN_PACKAGE)"; fi

# composer require --dev phpstan/extension-installer
# composer require --dev phpstan/phpstan-strict-rules phpstan/phpstan-phpunit phpstan/phpstan-doctrine phpstan/phpstan-symfony phpstan/phpstan-deprecation-rules

# Run PHPStan
# @see https://phpstan.org/
phpstan: $(wildcard $(PHPSTAN_CONFIG)) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_FLAGS), $(PHPSTAN_FLAGS)) analyse$(if $(PHPSTAN_DIRECTORIES_TO_CHECK), $(PHPSTAN_DIRECTORIES_TO_CHECK))
.PHONY: phpstan

# Generate a baseline for PHPStan
phpstan-baseline.neon: $(PHPSTAN_CONFIG) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_BASELINE_FLAGS), $(PHPSTAN_BASELINE_FLAGS)) --generate-baseline="$(if $(PHPSTAN_BASELINE),$(PHPSTAN_BASELINE),$(firstword $(PHPSTAN_POSSIBLE_BASELINES)))"
.PRECIOUS: phpstan-baseline.neon

# Clear the PHPStan cache
phpstan.clear-cache:: $(PHPSTAN_CONFIG) | $(PHPSTAN_DEPENDENCY)
	@$(PHPSTAN)$(if $(PHPSTAN_CLEAR_CACHE_FLAGS), $(PHPSTAN_CLEAR_CACHE_FLAGS)) clear-result-cache
.PHONY: phpstan.clear-cache
