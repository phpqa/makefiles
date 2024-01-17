###
##. Configuration
###

#. Package variables
PHPUNIT_PACKAGE?=phpunit/phpunit
ifeq ($(PHPUNIT_PACKAGE),)
$(error The variable PHPUNIT_PACKAGE should never be empty)
endif

PHPUNIT?=$(or $(PHP),php) vendor/bin/phpunit
ifeq ($(PHPUNIT),)
$(error The variable PHPUNIT should never be empty)
endif

ifeq ($(PHPUNIT),$(or $(PHP),php) vendor/bin/phpunit)
PHPUNIT_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpunit
else
PHPUNIT_DEPENDENCY?=$(wildcard $(PHPUNIT))
endif
ifeq ($(PHPUNIT_DEPENDENCY),)
$(error The variable PHPUNIT_DEPENDENCY should never be empty)
endif

#. Register as a tool
PHP_TESTING_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY))
PHP_QUALITY_ASSURANCE_REPORT_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY)))

#. Configuration variables
PHPUNIT_POSSIBLE_CONFIGS?=phpunit.xml phpunit.xml.dist
PHPUNIT_CONFIG?=$(firstword $(wildcard $(PHPUNIT_POSSIBLE_CONFIGS)))

#. Report variables
PHPUNIT_REPORT_DIRECTORY?=

#. Building the flags
PHPUNIT_FLAGS?=

ifneq ($(wildcard $(PHPUNIT_CONFIG)),)
ifeq ($(findstring --configuration,$(PHPUNIT_FLAGS)),)
PHPUNIT_FLAGS+=--configuration="$(PHPUNIT_CONFIG)"
endif
endif

ifneq ($(PHPUNIT_REPORT_DIRECTORY),)
ifeq ($(findstring --coverage-html,$(PHPUNIT_FLAGS)),)
PHPUNIT_FLAGS+=--coverage-html="$(PHPUNIT_REPORT_DIRECTORY)"
endif
endif

###
##. PHPUnit
##. A programmer-oriented testing framework for PHP
##. @see https://phpunit.de/
###

ifneq ($(COMPOSER_EXECUTABLE),)
# Install PHPUnit as dev dependency in vendor
vendor/bin/phpunit: | $(if $(wildcard vendor/bin/phpunit),,$(COMPOSER_DEPENDENCY) vendor)
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PHPUNIT_PACKAGE)"; fi
endif

#. Initialize PHPUnit
$(PHPUNIT_POSSIBLE_CONFIGS): | $(PHPUNIT_DEPENDENCY)
	@$(PHPUNIT) --generate-configuration
	@if test "phpunit.xml" != "$(@)"; then mv "phpunit.xml" "$(@)"; fi

# Run PHPUnit
# @see https://phpunit.de/
phpunit: | $(PHPUNIT_DEPENDENCY) $(PHPUNIT_CONFIG)
	@$(PHPUNIT)$(if $(PHPUNIT_FLAGS), $(PHPUNIT_FLAGS))
.PHONY: phpunit
PHP_TESTING_TOOLS+=phpunit

ifneq ($(PHPUNIT_REPORT_DIRECTORY),)
PHP_QUALITY_ASSURANCE_REPORT_TOOLS+=phpunit

#. List the PHPUnit report
phpunit.report.list:
	@$(if $(wildcard $(PHPUNIT_REPORT_DIRECTORY)/index.html),printf "%s: %s\n" "PHPUnit" "$$($(call println_link,file://$(abspath $(PHPUNIT_REPORT_DIRECTORY)/index.html,$(PHPUNIT_REPORT_DIRECTORY)/index.html)))")
.PHONY: phpunit.report.list

#. Remove the PHPUnit report
phpunit.report.remove:
	@$(if $(wildcard $(PHPUNIT_REPORT_DIRECTORY)/index.html),rm -rf $(PHPUNIT_REPORT_DIRECTORY))
.PHONY: phpunit.report.remove
endif
