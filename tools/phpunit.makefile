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
PHPUNIT?=$(PHP) vendor/bin/phpunit
ifeq ($(PHPUNIT),$(PHP) vendor/bin/phpunit)
PHPUNIT_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpunit
else
PHPUNIT_DEPENDENCY?=$(wildcard $(PHPUNIT))
endif
PHP_TESTING_TOOLS+=phpunit
PHP_TESTING_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY)))

#. Configuration variables
PHPUNIT_POSSIBLE_CONFIGS?=phpunit.xml phpunit.xml.dist
PHPUNIT_CONFIG?=$(firstword $(wildcard $(PHPUNIT_POSSIBLE_CONFIGS)))

#. Extra variables
PHPUNIT_COVERAGE_DIRECTORY?=
PHPUNIT_JUNIT?=

#. Building the flags
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
## Testing
###

# Install PHPUnit as dev dependency in vendor
vendor/bin/phpunit: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpunit/phpunit; fi

#. Initialize PHPUnit
$(PHPUNIT_POSSIBLE_CONFIGS): | $(PHPUNIT_DEPENDENCY)
	@$(PHPUNIT) --generate-configuration
	@if test "phpunit.xml" != "$(@)"; then mv "phpunit.xml" "$(@)"; fi

# Run PHPUnit
# @see https://phpunit.de/
phpunit: | $(PHPUNIT_DEPENDENCY) $(PHPUNIT_CONFIG)
	@$(PHPUNIT)$(if $(PHPUNIT_FLAGS), $(PHPUNIT_FLAGS))
.PHONY: phpunit
