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
PHPCS_PACKAGE?=squizlabs/php_codesniffer
PHPCS?=$(PHP) vendor/bin/phpcs
ifeq ($(PHPCS),$(PHP) vendor/bin/phpcs)
PHPCS_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpcs
else
PHPCS_DEPENDENCY?=$(wildcard $(PHPCS))
endif
PHPCBF_PACKAGE?=squizlabs/php_codesniffer
PHPCBF?=$(PHP) vendor/bin/phpcbf
ifeq ($(PHPCBF),$(PHP) vendor/bin/phpcbf)
PHPCBF_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/phpcbf
else
PHPCBF_DEPENDENCY?=$(wildcard $(PHPCBF))
endif

#. Configuration variables
PHPCS_POSSIBLE_STANDARDS?=.phpcs.xml phpcs.xml .phpcs.xml.dist phpcs.xml.dist
PHPCS_STANDARD?=$(firstword $(wildcard $(PHPCS_POSSIBLE_STANDARDS)))
PHPCBF_STANDARD?=$(PHPCS_STANDARD)

#. Extra variables
PHPCS_DIRECTORIES_TO_CHECK?=$(if $(wildcard $(PHPCS_POSSIBLE_STANDARDS)),,src)
PHPCBF_DIRECTORIES_TO_CHECK?=$(PHPCS_DIRECTORIES_TO_CHECK)

#. Building the flags
PHPCS_FLAGS?=
PHPCBF_FLAGS?=

ifneq ($(wildcard $(PHPCS_STANDARD)),)
ifeq ($(findstring --standard,$(PHPCS_FLAGS)),)
PHPCS_FLAGS+=--standard="$(PHPCS_STANDARD)"
endif
endif

ifneq ($(wildcard $(PHPCBF_STANDARD)),)
ifeq ($(findstring --standard,$(PHPCBF_FLAGS)),)
PHPCBF_FLAGS+=--standard="$(PHPCBF_STANDARD)"
endif
endif

###
## PHP Quality Assurance Tools
###

ifeq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCS_DEPENDENCY))),)

# Install PHP_CodeSniffer as dev dependency in vendor # TODO Also add installation as phar
vendor/bin/phpcs: | $(COMPOSER_DEPENDENCY) vendor
	@$(COMPOSER_EXECUTABLE) require --dev "$(PHPCS_PACKAGE)"

else

# Run PHP_CodeSniffer
# @see https://github.com/squizlabs/PHP_CodeSniffer
phpcs: | $(wildcard $(PHPCS_STANDARD)) $(PHPCS_DEPENDENCY)
	@$(PHPCS)$(if $(PHPCS_FLAGS), $(PHPCS_FLAGS)) $(PHPCS_DIRECTORIES_TO_CHECK)
.PHONY: phpcs

endif

ifeq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCBF_DEPENDENCY))),)

#. Install PHP_CodeSniffer as dev dependency in vendor # TODO Also add installation as phar
vendor/bin/phpcbf: | $(COMPOSER_DEPENDENCY) vendor
	@$(COMPOSER_EXECUTABLE) require --dev "$(PHPCBF_PACKAGE)"

else

# Run PHP Code Beautifier and Fixer #!
# @see https://github.com/squizlabs/PHP_CodeSniffer
phpcbf: | $(wildcard $(PHPCBF_STANDARD)) $(PHPCBF_DEPENDENCY)
	@$(PHPCBF)$(if $(PHPCBF_FLAGS), $(PHPCBF_FLAGS)) $(PHPCBF_DIRECTORIES_TO_CHECK)
.PHONY: phpcbf

endif
