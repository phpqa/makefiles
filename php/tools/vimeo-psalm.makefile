###
##. Configuration
###

#. Package variables
PSALM_PACKAGE?=psalm/phar
ifeq ($(PSALM_PACKAGE),)
$(error The variable PSALM_PACKAGE should never be empty)
endif

PSALM?=$(or $(PHP),php) vendor/bin/psalm
ifeq ($(PSALM),)
$(error The variable PSALM should never be empty)
endif

ifeq ($(PSALM),$(or $(PHP),php) vendor/bin/psalm)
PSALM_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/psalm
else
PSALM_DEPENDENCY?=$(wildcard $(PSALM))
endif
ifeq ($(PSALM_DEPENDENCY),)
$(error The variable PSALM_DEPENDENCY should never be empty)
endif

#. Register as a tool
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PSALM_DEPENDENCY))
PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PSALM_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PSALM_DEPENDENCY)))

#. Tool variables
PSALM_POSSIBLE_CONFIGS?=psalm.xml
PSALM_CONFIG?=$(wildcard $(PSALM_POSSIBLE_CONFIGS))

PSALM_POSSIBLE_BASELINES?=psalm-baseline.xml
PSALM_BASELINE?=$(wildcard $(PSALM_POSSIBLE_BASELINES))

PSALTER_ISSUES?=

#. Building the flags
PSALM_FLAGS?=
PSALM_BASELINE_FLAGS?=

ifneq ($(wildcard $(PSALM_CONFIG)),)
ifeq ($(findstring --config,$(PSALM_FLAGS)),)
PSALM_FLAGS+=--config="$(PSALM_CONFIG)"
endif
ifeq ($(findstring --config,$(PSALM_BASELINE_FLAGS)),)
PSALM_BASELINE_FLAGS+=--config="$(PSALM_CONFIG)"
endif
endif

###
##. Psalm
##. A static analysis tool that attempts to dig into your program and find as many type-related bugs as possible
##. @see https://psalm.dev/docs/
###

ifneq ($(COMPOSER_EXECUTABLE),)
# Install Psalm as dev dependency in vendor
vendor/bin/psalm: | $(if $(wildcard vendor/bin/psalm),,$(COMPOSER_DEPENDENCY) vendor)
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PSALM_PACKAGE)"; fi
endif

#. Initialize Psalm # TODO This needs a HOME environment variable to be overwritten https://github.com/vimeo/psalm/issues/4267
psalm.xml: | $(PSALM_DEPENDENCY)
	@$(PSALM) --init

# Run Psalm
# @see https://psalm.dev/docs/
psalm: | $(PSALM_DEPENDENCY) $(PSALM_CONFIG)
	@$(PSALM)$(if $(PSALM_FLAGS), $(PSALM_FLAGS))$(if $(PSALM_BASELINE), --use-baseline="$(PSALM_BASELINE)" --update-baseline)
.PHONY: psalm
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=psalm

# Generate a baseline for Psalm
psalm-baseline.xml: | $(PSALM_DEPENDENCY) $(PSALM_CONFIG)
	@$(PSALM)$(if $(PSALM_BASELINE_FLAGS), $(PSALM_BASELINE_FLAGS)) --set-baseline="$(if $(PSALM_BASELINE),$(PSALM_BASELINE),$(firstword $(PSALM_POSSIBLE_BASELINES)))"
.PRECIOUS: psalm-baseline.xml

# Clear the Psalm cache
psalm.clear-cache:
	@$(PSALM)$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --clear-cache
.PHONY: psalm.clear-cache

# Run Psalter #!
# @see https://psalm.dev/docs/manipulating_code/fixing/
psalter: | $(PSALM_DEPENDENCY) $(PSALM_CONFIG)
	@$(PSALM) --alter$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --issues="$(if $(PSALTER_ISSUES),$(PSALTER_ISSUES),all)"
.PHONY: psalter
PHP_QUALITY_ASSURANCE_FIX_TOOLS+=psalter

# Dryrun Psalter
psalter.dryrun: | $(PSALM_DEPENDENCY) $(PSALM_CONFIG)
	@$(PSALM) --alter --dry-run$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --issues="$(if $(PSALTER_ISSUES),$(PSALTER_ISSUES),all)"
.PHONY: psalter.dryrun
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=psalter.dryrun
