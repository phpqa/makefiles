###
##. Configuration
###

PHP_CHECK_TOOLS?=\
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PARALLEL_LINT_DEPENDENCY))),parallel-lint) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(COMPOSER_DEPENDENCY))),composer.validate composer.check-platform-reqs) \
	$(if $(wildcard $(filter-out $(COMPOSER_DEPENDENCY),$(COMPOSER_NORMALIZE_DEPENDENCY))),composer-normalize.dryrun) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCS_DEPENDENCY))),phpcs) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCSFIXER_DEPENDENCY))),php-cs-fixer.dryrun) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPSTAN_DEPENDENCY))),phpstan) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PSALM_DEPENDENCY))),psalm psalter.dryrun) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY))),rector.dryrun)

PHP_FIX_TOOLS?=\
	$(if $(wildcard $(filter-out $(COMPOSER_DEPENDENCY),$(COMPOSER_NORMALIZE_DEPENDENCY))),composer-normalize) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PSALM_DEPENDENCY))),psalter) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(RECTOR_DEPENDENCY))),rector) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCBF_DEPENDENCY))),phpcbf) \
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPCSFIXER_DEPENDENCY))),php-cs-fixer)

###
## PHP Quality Assurance Tools
## ! If you include this file, always include it AFTER the makefiles of the tools
###

ifneq ($(PHP_CHECK_TOOLS),)

# Run a complete analysis
php.check: $(PHP_CHECK_TOOLS)
.PHONY: php.check

endif

ifneq ($(PHP_FIX_TOOLS),)

# Fix your files #!
php.fix: $(PHP_FIX_TOOLS)
.PHONY: php.fix

endif
