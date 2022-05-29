###
## PHP Quality Assurance Tools
## ! If you include this file, always include it AFTER the makefiles of the tools
###

# Run a complete analysis
php.check:\
	$(if $(PARALLEL_LINT),parallel-lint) \
	$(if $(findstring composer.makefile,$(MAKEFILE_LIST)),composer.validate composer.check-platform-reqs) \
	$(if $(findstring composer-normalize.makefile,$(MAKEFILE_LIST)),composer-normalize.dryrun) \
	$(if $(PHPCS),phpcs) \
	$(if $(PHPCSFIXER),php-cs-fixer.dryrun) \
	$(if $(PHPSTAN),phpstan) \
	$(if $(PSALM),psalm psalter.dryrun) \
	$(if $(RECTOR),rector.dryrun)
	@true
.PHONY: php.check

# Fix your files #!
php.fix:\
	$(if $(findstring composer-normalize.makefile,$(MAKEFILE_LIST)),composer-normalize) \
	$(if $(PSALM),psalter) \
	$(if $(RECTOR),rector) \
	$(if $(PHPCBF),phpcbf) \
	$(if $(PHPCSFIXER),php-cs-fixer)
	@true
.PHONY: php.fix
