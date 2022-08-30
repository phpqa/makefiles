###
##. Configuration
###

#. Package variables
PHPUNIT_PACKAGE?=phpunit/phpunit
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
##. Requirements
###

ifeq ($(PHP),)
$(error The variable PHP should never be empty.)
endif
ifeq ($(PHP_DEPENDENCY),)
$(error The variable PHP_DEPENDENCY should never be empty.)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
$(error The variable COMPOSER_EXECUTABLE should never be empty.)
endif
ifeq ($(COMPOSER_DEPENDENCY),)
$(error The variable COMPOSER_DEPENDENCY should never be empty.)
endif
ifeq ($(PHPUNIT_PACKAGE),)
$(error The variable PHPUNIT_PACKAGE should never be empty.)
endif
ifeq ($(PHPUNIT),)
$(error The variable PHPUNIT should never be empty.)
endif
ifeq ($(PHPUNIT_DEPENDENCY),)
$(error The variable PHPUNIT_DEPENDENCY should never be empty.)
endif

###
## Testing
###

# Install PHPUnit as dev dependency in vendor
vendor/bin/phpunit: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PHPUNIT_PACKAGE)"; fi

#. Initialize PHPUnit
$(PHPUNIT_POSSIBLE_CONFIGS): | $(PHPUNIT_DEPENDENCY)
	@$(PHPUNIT) --generate-configuration
	@if test "phpunit.xml" != "$(@)"; then mv "phpunit.xml" "$(@)"; fi

# Run PHPUnit
# @see https://phpunit.de/
phpunit: | $(PHPUNIT_DEPENDENCY) $(PHPUNIT_CONFIG)
	@$(PHPUNIT)$(if $(PHPUNIT_FLAGS), $(PHPUNIT_FLAGS))
.PHONY: phpunit
