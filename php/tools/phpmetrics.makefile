###
##. Configuration
###

#. Package variables
PHPMETRICS_PACKAGE?=phpmetrics/phpmetrics
ifeq ($(PHPMETRICS_PACKAGE),)
$(error The variable PHPMETRICS_PACKAGE should never be empty)
endif

PHPMETRICS?=$(or $(PHP),php) vendor/bin/phpmetrics
ifeq ($(PHPMETRICS),)
$(error The variable PHPMETRICS should never be empty)
endif

ifeq ($(PHPMETRICS),$(or $(PHP),php) vendor/bin/phpmetrics)
PHPMETRICS_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpmetrics
else
PHPMETRICS_DEPENDENCY?=$(wildcard $(PHPMETRICS))
endif
ifeq ($(PHPMETRICS_DEPENDENCY),)
$(error The variable PHPMETRICS_DEPENDENCY should never be empty)
endif

#. Register as a tool
PHP_QUALITY_ASSURANCE_REPORT_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPMETRICS_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPMETRICS_DEPENDENCY)))

#. Configuration variables
PHPMETRICS_DIRECTORIES_TO_CHECK?=.

#. Report variables
PHPMETRICS_REPORT_DIRECTORY?=

#. Building the flags
PHPMETRICS_FLAGS?=

ifneq ($(PHPMETRICS_REPORT_DIRECTORY),)
ifeq ($(findstring --report-html,$(PHPMETRICS_FLAGS)),)
PHPMETRICS_FLAGS+=--report-html="$(PHPMETRICS_REPORT_DIRECTORY)"
endif
endif

###
##. PhpMetrics
##. A static analysis tool for PHP
##. @see https://phpmetrics.org/
###

ifneq ($(COMPOSER_EXECUTABLE),)
# Install PhpMetrics as dev dependency in vendor
vendor/bin/phpmetrics: | $(if $(wildcard vendor/bin/phpmetrics),,$(COMPOSER_DEPENDENCY) vendor)
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PHPMETRICS_PACKAGE)"; fi
endif

# Run PhpMetrics
# @see https://phpmetrics.org/
phpmetrics: | $(PHPMETRICS_DEPENDENCY) $(PHPMETRICS_CONFIG)
	@$(PHPMETRICS)$(if $(PHPMETRICS_FLAGS), $(PHPMETRICS_FLAGS)) $(PHPMETRICS_DIRECTORIES_TO_CHECK)
.PHONY: phpmetrics

ifneq ($(PHPMETRICS_REPORT_DIRECTORY),)
PHP_QUALITY_ASSURANCE_REPORT_TOOLS+=phpmetrics

#. List the PhpMetrics report
phpmetrics.report.list:
	@$(if $(wildcard $(PHPMETRICS_REPORT_DIRECTORY)/index.html),printf "%s: %s\n" "PhpMetrics" "$$($(call println_link,file://$(abspath $(PHPMETRICS_REPORT_DIRECTORY)/index.html,$(PHPMETRICS_REPORT_DIRECTORY)/index.html)))")
.PHONY: phpmetrics.report.list

#. Remove the PhpMetrics report
phpmetrics.report.remove:
	@$(if $(wildcard $(PHPMETRICS_REPORT_DIRECTORY)/index.html),rm -rf $(PHPMETRICS_REPORT_DIRECTORY))
.PHONY: phpmetrics.report.remove
endif
