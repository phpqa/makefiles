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
PHPCSFIXER_PACKAGE?=friendsofphp/php-cs-fixer
PHPCSFIXER?=$(PHP) vendor/bin/php-cs-fixer
ifeq ($(PHPCSFIXER),$(PHP) vendor/bin/php-cs-fixer)
PHPCSFIXER_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/php-cs-fixer
else
PHPCSFIXER_DEPENDENCY?=$(wildcard $(PHPCSFIXER))
endif
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=php-cs-fixer.dryrun
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPCSFIXER_DEPENDENCY))
PHP_QUALITY_ASSURANCE_FIX_TOOLS+=php-cs-fixer
PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PHPCSFIXER_DEPENDENCY))
HELP_SKIP_TARGETS+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCSFIXER_DEPENDENCY)))

#. Tool variables
PHPCSFIXER_POSSIBLE_CONFIGS?=.php-cs-fixer.dist.php .php-cs-fixer.php
PHPCSFIXER_CONFIG?=$(firstword $(wildcard $(PHPCSFIXER_POSSIBLE_CONFIGS)))

PHPCSFIXER_DIRECTORIES_TO_CHECK?=$(if $(PHPCSFIXER_CONFIG),,.)

#. Building the flags
PHPCSFIXER_FLAGS?=

ifneq ($(wildcard $(PHPCSFIXER_CONFIG)),)
ifeq ($(findstring --config,$(PHPCSFIXER_FLAGS)),)
PHPCSFIXER_FLAGS+=--config="$(PHPCSFIXER_CONFIG)"
endif
endif

###
## Quality Assurance
###

# Install PHP Coding Standards Fixer as dev dependency in vendor
vendor/bin/php-cs-fixer: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PHPCSFIXER_PACKAGE)"; fi

# Run PHP Coding Standards Fixer #!
# @see https://github.com/FriendsOfPHP/PHP-CS-Fixer
php-cs-fixer: | $(wildcard $(PHPCSFIXER_STANDARD)) $(PHPCSFIXER_DEPENDENCY)
	@$(PHPCSFIXER) fix --diff$(if $(PHPCSFIXER_FLAGS), $(PHPCSFIXER_FLAGS)) $(PHPCSFIXER_DIRECTORIES_TO_CHECK)
.PHONY: php-cs-fixer

# Dryrun PHP Coding Standards Fixer
php-cs-fixer.dryrun: | $(wildcard $(PHPCSFIXER_STANDARD)) $(PHPCSFIXER_DEPENDENCY)
	@$(PHPCSFIXER) fix --dry-run --diff$(if $(PHPCSFIXER_FLAGS), $(PHPCSFIXER_FLAGS)) $(PHPCSFIXER_DIRECTORIES_TO_CHECK)
.PHONY: php-cs-fixer.dryrun
