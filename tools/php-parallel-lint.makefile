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
PARALLEL_LINT_PACKAGE?=php-parallel-lint/php-parallel-lint
PARALLEL_LINT?=$(PHP) vendor/bin/parallel-lint
ifeq ($(PARALLEL_LINT),$(PHP) vendor/bin/parallel-lint)
PARALLEL_LINT_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/parallel-lint
else
PARALLEL_LINT_DEPENDENCY?=$(wildcard $(PARALLEL_LINT))
endif
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=parallel-lint
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(PARALLEL_LINT_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(PARALLEL_LINT_DEPENDENCY)))

#. Tool variables
PARALLEL_LINT_DIRECTORIES_TO_CHECK?=.

#. Building the flags
PARALLEL_LINT_FLAGS?=

ifneq ($(wildcard vendor),)
ifeq ($(findstring --exclude vendor,$(PARALLEL_LINT_FLAGS)),)
PARALLEL_LINT_FLAGS+=--exclude vendor
endif
endif

ifneq ($(GIT),)
ifeq ($(findstring --blame,$(PARALLEL_LINT_FLAGS)),)
PARALLEL_LINT_FLAGS+=--blame
endif
endif

###
## Quality Assurance
###

# Install Parallel Lint as dev dependency in vendor
vendor/bin/parallel-lint: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(PARALLEL_LINT_PACKAGE)"; fi

# Run Parallel Lint
# Checks the syntax of PHP files in parallel
# @see https://github.com/php-parallel-lint/PHP-Parallel-Lint
parallel-lint: | $(PARALLEL_LINT_DEPENDENCY) $(if $(COMPOSER),$(patsubst %.json,%.lock,$(COMPOSER)),composer.lock)
	@$(PARALLEL_LINT)$(if $(PARALLEL_LINT_FLAGS), $(PARALLEL_LINT_FLAGS)) $(PARALLEL_LINT_DIRECTORIES_TO_CHECK)
.PHONY: parallel-lint