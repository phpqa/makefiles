###
##. Dependencies
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
##. Configuration
###

#. Package variables
COMPOSER_NORMALIZE_PACKAGE?=ergebnis/composer-normalize
COMPOSER_NORMALIZE?=$(COMPOSER_EXECUTABLE) normalize
ifeq ($(COMPOSER_NORMALIZE),$(COMPOSER_EXECUTABLE) normalize)
COMPOSER_NORMALIZE_DEPENDENCY?=$(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
else
COMPOSER_NORMALIZE_DEPENDENCY?=$(wildcard $(COMPOSER_NORMALIZE))
endif

#. Building the flags
COMPOSER_NORMALIZE_FLAGS?=

###
## PHP Quality Assurance Tools
###

ifeq ($(wildcard $(filter-out $(COMPOSER_DEPENDENCY),$(COMPOSER_NORMALIZE_DEPENDENCY))),)

# Install composer-normalize as dev dependency in vendor
vendor/ergebnis/composer-normalize: | $(COMPOSER_DEPENDENCY) vendor
	@$(COMPOSER_EXECUTABLE) config allow-plugins.$(COMPOSER_NORMALIZE_PACKAGE) true
	@$(COMPOSER_EXECUTABLE) require --dev "$(COMPOSER_NORMALIZE_PACKAGE)"

endif

# Run composer-normalize #!
# @see https://github.com/ergebnis/composer-normalize
composer-normalize: | $(COMPOSER_NORMALIZE_DEPENDENCY)
	@$(COMPOSER_NORMALIZE)$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS))$(if $(COMPOSER), $(COMPOSER))

# Dryrun composer-normalize
composer-normalize.dryrun: | $(COMPOSER_NORMALIZE_DEPENDENCY)
	@$(COMPOSER_NORMALIZE)$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS)) --diff --dry-run$(if $(COMPOSER), $(COMPOSER))
