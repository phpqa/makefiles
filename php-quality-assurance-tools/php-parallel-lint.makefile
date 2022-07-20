###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

PARALLEL_LINT?=$(PHP) vendor/bin/parallel-lint
ifeq ($(PARALLEL_LINT),$(PHP) vendor/bin/parallel-lint)
PARALLEL_LINT_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/parallel-lint
else
PARALLEL_LINT_DEPENDENCY?=$(wildcard $(PARALLEL_LINT))
endif
PARALLEL_LINT_DIRECTORIES_TO_CHECK?=.
PARALLEL_LINT_FLAGS?=$(if $(wildcard vendor),--exclude vendor)
ifneq ($(GIT),)
ifeq ($(findstring --blame,$(PARALLEL_LINT_FLAGS)),)
PARALLEL_LINT_FLAGS+=--blame
endif
endif

###
## PHP Quality Assurance Tools
###

#. Install Parallel Lint
vendor/bin/parallel-lint: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev php-parallel-lint/php-parallel-lint; fi

ifneq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(PARALLEL_LINT_DEPENDENCY))),)

# Run Parallel Lint
# @see https://github.com/php-parallel-lint/PHP-Parallel-Lint
parallel-lint: | $(PARALLEL_LINT_DEPENDENCY) $(if $(COMPOSER),$(patsubst %.json,%.lock,$(COMPOSER)),composer.lock)
	@$(PARALLEL_LINT)$(if $(PARALLEL_LINT_FLAGS), $(PARALLEL_LINT_FLAGS)) $(PARALLEL_LINT_DIRECTORIES_TO_CHECK)
.PHONY: parallel-lint

endif
