###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

COMPOSER_NORMALIZE_FLAGS?=

###
## PHP Quality Assurance Tools
###

#. Install composer-normalize # TODO Add installing the phar file
vendor/ergebnis/composer-normalize: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev ergebnis/composer-normalize; fi
	@$(COMPOSER_EXECUTABLE) config allow-plugins.ergebnis/composer-normalize true

# Run composer-normalize #!
# @see https://github.com/ergebnis/composer-normalize
composer-normalize: | $(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
	@$(COMPOSER_EXECUTABLE) normalize$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS))$(if $(COMPOSER), $(COMPOSER))

# Dryrun composer-normalize
composer-normalize.dryrun: | $(COMPOSER_DEPENDENCY) vendor/ergebnis/composer-normalize
	@$(COMPOSER_EXECUTABLE) normalize$(if $(COMPOSER_NORMALIZE_FLAGS), $(COMPOSER_NORMALIZE_FLAGS)) --diff --dry-run$(if $(COMPOSER), $(COMPOSER))
