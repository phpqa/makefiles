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

PHPUNIT_POSSIBLE_CONFIGS?=phpstan.neon phpstan.neon.dist phpstan.dist.neon
PHPUNIT_CONFIG?=$(firstword $(wildcard $(PHPUNIT_POSSIBLE_CONFIGS)))
PHPUNIT_COVERAGE_DIRECTORY?=
PHPUNIT_JUNIT?=

PHPUNIT_FLAGS?=
ifneq ($(wildcard $(PHPUNIT_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPUNIT_FLAGS)),)
PHPUNIT_FLAGS+=--configuration="$(PHPUNIT_CONFIG)"
endif
endif

ifneq ($(PHPUNIT_COVERAGE_DIRECTORY),)
ifeq ($(findstring --coverage-html,$(PHPUNIT_FLAGS)),)
PHPUNIT_FLAGS+=--coverage-html="$(PHPUNIT_COVERAGE_DIRECTORY)"
endif
endif

ifneq ($(PHPUNIT_JUNIT),)
ifeq ($(findstring --log-junit,$(PHPUNIT_FLAGS)),)
PHPUNIT_FLAGS+=--log-junit="$(PHPUNIT_JUNIT)"
endif
endif

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
