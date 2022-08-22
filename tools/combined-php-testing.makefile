###
## Testing
## ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_TESTING_TOOLS?=
PHP_TESTING_TOOLS_TO_SKIP?=

ifneq ($(PHP_TESTING_TOOLS),)
# Run the tests
php.test: $(filter-out $(PHP_TESTING_TOOLS_TO_SKIP),$(PHP_TESTING_TOOLS))
	@true
.PHONY: php.test
endif
