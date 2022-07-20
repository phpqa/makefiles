###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

COMPOSER_NORMALIZE?=$(COMPOSER_EXECUTABLE) normalize
ifeq ($(COMPOSER_NORMALIZE),$(COMPOSER_EXECUTABLE) normalize)
COMPOSER_NORMALIZE_DEPENDENCY?=$(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
else
COMPOSER_NORMALIZE_DEPENDENCY?=$(wildcard $(COMPOSER_NORMALIZE))
endif

COMPOSER_NORMALIZE_FLAGS?=

###
## PHP Quality Assurance Tools
###

#. Install composer-normalize # TODO Add installing the phar file
vendor/ergebnis/composer-normalize: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev ergebnis/composer-normalize; fi
	@$(COMPOSER_EXECUTABLE) config allow-plugins.ergebnis/composer-normalize true

ifneq ($(wildcard $(filter-out $(COMPOSER_DEPENDENCY),$(COMPOSER_NORMALIZE_DEPENDENCY))),)

# Run composer-normalize #!
# @see https://github.com/ergebnis/composer-normalize
composer-normalize: | $(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
	@$(COMPOSER_NORMALIZE)$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS))$(if $(COMPOSER), $(COMPOSER))

# Dryrun composer-normalize
composer-normalize.dryrun: | $(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
	@$(COMPOSER_NORMALIZE)$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS)) --diff --dry-run$(if $(COMPOSER), $(COMPOSER))

endif
