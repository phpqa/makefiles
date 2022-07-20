###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PHPCS?=$(PHP) vendor/bin/phpcs
ifeq ($(PHPCS),$(PHP) vendor/bin/phpcs)
PHPCS_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpcs
else
PHPCS_DEPENDENCY?=$(wildcard $(PHPCS))
endif

PHPCS_POSSIBLE_STANDARDS?=.phpcs.xml phpcs.xml .phpcs.xml.dist phpcs.xml.dist
PHPCS_STANDARD?=$(firstword $(wildcard $(PHPCS_POSSIBLE_STANDARDS)))
PHPCS_DIRECTORIES_TO_CHECK?=$(if $(wildcard $(PHPCS_POSSIBLE_STANDARDS)),,src)
PHPCS_FLAGS?=
ifneq ($(wildcard $(PHPCS_STANDARD)),)
ifeq ($(findstring --standard,$(PHPCS_FLAGS)),)
PHPCS_FLAGS+=--standard="$(PHPCS_STANDARD)"
endif
endif

PHPCBF?=$(PHP) vendor/bin/phpcbf
ifeq ($(PHPCBF),$(PHP) vendor/bin/phpcbf)
PHPCBF_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpcbf
else
PHPCBF_DEPENDENCY?=$(wildcard $(PHPCBF))
endif

PHPCBF_STANDARD?=$(PHPCS_STANDARD)
PHPCBF_DIRECTORIES_TO_CHECK?=$(PHPCS_DIRECTORIES_TO_CHECK)
PHPCBF_FLAGS?=
ifneq ($(wildcard $(PHPCBF_STANDARD)),)
ifeq ($(findstring --standard,$(PHPCBF_FLAGS)),)
PHPCBF_FLAGS+=--standard="$(PHPCBF_STANDARD)"
endif
endif

###
## PHP Quality Assurance Tools
###

#. Install PHP_CodeSniffer # TODO Also add installation as phar
vendor/bin/phpcs: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev squizlabs/php_codesniffer; fi

ifneq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCS_DEPENDENCY))),)

# Run PHP_CodeSniffer
# @see https://github.com/squizlabs/PHP_CodeSniffer
phpcs: | $(wildcard $(PHPCS_STANDARD)) $(PHPCS_DEPENDENCY)
	@$(PHPCS)$(if $(PHPCS_FLAGS), $(PHPCS_FLAGS)) $(PHPCS_DIRECTORIES_TO_CHECK)
.PHONY: phpcs

endif

#. Install PHP_CodeSniffer # TODO Also add installation as phar
vendor/bin/phpcbf: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev squizlabs/php_codesniffer; fi

ifneq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCBF_DEPENDENCY))),)

# Run PHP Code Beautifier and Fixer #!
# @see https://github.com/squizlabs/PHP_CodeSniffer
phpcbf: | $(wildcard $(PHPCBF_STANDARD)) bin/php vendor/bin/phpcbf
	@$(PHPCBF)$(if $(PHPCBF_FLAGS), $(PHPCBF_FLAGS)) $(PHPCBF_DIRECTORIES_TO_CHECK)
.PHONY: phpcbf

endif
