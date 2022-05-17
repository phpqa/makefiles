###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PHPCSFIXER?=$(PHP) vendor/bin/php-cs-fixer
ifeq ($(PHPCSFIXER),$(PHP) vendor/bin/php-cs-fixer)
PHPCSFIXER_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/php-cs-fixer
else
PHPCSFIXER_DEPENDENCY?=$(wildcard $(PHPCSFIXER))
endif

PHPCSFIXER_DIRECTORIES_TO_CHECK?=
PHPCSFIXER_CONFIG?=$(firstword $(wildcard ..php-cs-fixer.dist.php .php-cs-fixer.php))
PHPCSFIXER_FLAGS?=
ifneq ($(wildcard $(PHPCSFIXER_CONFIG)),)
ifeq ($(findstring --config,$(PHPCSFIXER_FLAGS)),)
PHPCSFIXER_FLAGS+=--config="$(PHPCSFIXER_CONFIG)"
endif
endif

###
## Quality Assurance Tools
###

#. Install PHP Coding Standards Fixer # TODO Also add installation as phar
vendor/bin/php-cs-fixer: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev friendsofphp/php-cs-fixer; fi

# Run PHP Coding Standards Fixer #! will change code
# @see https://github.com/FriendsOfPHP/PHP-CS-Fixer
php-cs-fixer: | $(wildcard $(PHPCSFIXER_STANDARD)) $(PHPCSFIXER_DEPENDENCY)
	@$(PHPCSFIXER) fix --dry-run --diff$(if $(PHPCSFIXER_FLAGS), $(PHPCSFIXER_FLAGS)) $(PHPCSFIXER_DIRECTORIES_TO_CHECK)
.PHONY: php-cs-fixer

# Dryrun PHP Coding Standards Fixer
php-cs-fixer-dryrun: | $(wildcard $(PHPCSFIXER_STANDARD)) $(PHPCSFIXER_DEPENDENCY)
	@$(PHPCSFIXER) fix --dry-run --diff$(if $(PHPCSFIXER_FLAGS), $(PHPCSFIXER_FLAGS)) $(PHPCSFIXER_DIRECTORIES_TO_CHECK)
.PHONY: php-cs-fixer-dryrun
