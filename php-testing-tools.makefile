###
##. Configuration
###

PHP_TESTING_TOOLS_DIRECTORY?=$(wildcard $(patsubst %.makefile,%,$(filter %/php-testing-tools.makefile,$(MAKEFILE_LIST))))
ifeq ($(PHP_TESTING_TOOLS_DIRECTORY),)
$(error Please provide the variable PHP_TESTING_TOOLS_DIRECTORY before including this file.)
endif

###
##. PHP Testing Tools
###

include $(PHP_TESTING_TOOLS_DIRECTORY)/phpunit.makefile
include $(PHP_TESTING_TOOLS_DIRECTORY)/combined.makefile
