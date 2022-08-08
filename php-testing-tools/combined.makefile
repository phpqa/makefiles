###
##. Configuration
###

PHP_TESTING_TOOLS?=\
	$(if $(wildcard $(filter-out $(PHP_DEPENDENCY),$(PHPUNIT_DEPENDENCY))),phpunit)

###
## PHP Testing Tools
## ! If you include this file, always include it AFTER the makefiles of the tools
###

ifneq ($(PHP_TESTING_TOOLS),)

# Run all tests
php.test: $(PHP_TESTING_TOOLS)
.PHONY: php.test

endif
