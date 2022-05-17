###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PHPUNIT?=$(PHP) vendor/bin/phpunit
ifeq ($(PHPUNIT),$(PHP) vendor/bin/phpunit)
PHPUNIT_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpunit
else
PHPUNIT_DEPENDENCY?=$(wildcard $(PHPUNIT))
endif
PHPUNIT_FLAGS?=

###
## PHP Testing Tools
###

#. Install PHPUnit
vendor/bin/phpunit: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpunit/phpunit; fi

#. Initialize PHPUnit
phpunit.xml.dist: | $(PHPUNIT_DEPENDENCY)
	@$(PHPUNIT) --generate-configuration

# Run PHPUnit
# @see https://phpunit.de/
phpunit: | $(PHPUNIT_DEPENDENCY) phpunit.xml.dist
	@$(PHPUNIT)$(if $(PHPUNIT_FLAGS), $(PHPUNIT_FLAGS))
.PHONY: phpunit
