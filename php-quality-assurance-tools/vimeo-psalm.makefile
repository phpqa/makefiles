###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PSALM?=$(PHP) vendor/bin/psalm
ifeq ($(PSALM),$(PHP) vendor/bin/psalm)
PSALM_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/psalm
else
PSALM_DEPENDENCY?=$(wildcard $(PSALM))
endif

PSALM_CONFIG?=psalm.xml
PSALM_BASELINE?=$(wildcard psalm-baseline.xml)
PSALM_FLAGS?=
ifneq ($(wildcard $(PSALM_CONFIG)),)
ifeq ($(findstring --config,$(PSALM_FLAGS)),)
PSALM_FLAGS+=--config="$(PSALM_CONFIG)"
endif
endif

PSALTER_ISSUES?=

###
## PHP Quality Assurance Tools
###

#. Install Psalm # TODO Also add installation as phar
vendor/bin/psalm: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev vimeo/psalm; fi

#. Initialize Psalm # TODO This needs a HOME environment variable to be overwritten https://github.com/vimeo/psalm/issues/4267
psalm.xml: | $(PSALM_DEPENDENCY)
	@$(PSALM) --init

# Run Psalm
# @see https://psalm.dev/docs/
psalm: | $(PSALM_CONFIG) $(PSALM_DEPENDENCY)
	@$(PSALM)$(if $(PSALM_FLAGS), $(PSALM_FLAGS))$(if $(PSALM_BASELINE), --use-baseline="$(PSALM_BASELINE)" --update-baseline)
.PHONY: psalm

# Generate a baseline for Psalm
psalm-baseline.xml: | $(PSALM_CONFIG) $(PSALM_DEPENDENCY)
	@$(PSALM)$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --set-baseline="$(if $(PSALM_BASELINE),$(PSALM_BASELINE),psalm-baseline.xml)"

# Clear the Psalm cache
psalm.clear-cache:
	@$(PSALM)$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --clear-cache
.PHONY: psalm.clear-cache

# Run Psalter #!
# @see https://psalm.dev/docs/manipulating_code/fixing/
psalter: | $(PSALM_CONFIG) $(PSALM_DEPENDENCY)
	@$(PSALM) --alter$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --issues="$(if $(PSALTER_ISSUES),$(PSALTER_ISSUES),all)"
.PHONY: psalter

# Dryrun Psalter
psalter.dryrun: | $(PSALM_CONFIG) $(PSALM_DEPENDENCY)
	@$(PSALM) --alter --dry-run$(if $(PSALM_FLAGS), $(PSALM_FLAGS)) --issues="$(if $(PSALTER_ISSUES),$(PSALTER_ISSUES),all)"
.PHONY: psalter.dryrun
