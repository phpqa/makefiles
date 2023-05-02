###
##. Testing tools
##. ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_TESTING_TOOLS?=
PHP_TESTING_TOOLS_DEPENDENCIES?=
PHP_TESTING_TOOLS_TO_SKIP?=

ifneq ($(PHP_TESTING_TOOLS),)
#. Install all test tools
php.test.install: | $(PHP_TESTING_TOOLS_DEPENDENCIES)
.PHONY: php.test.install

# Run the tests
php.test: $(filter-out $(PHP_TESTING_TOOLS_TO_SKIP),$(PHP_TESTING_TOOLS)); @true
.PHONY: php.test
endif
