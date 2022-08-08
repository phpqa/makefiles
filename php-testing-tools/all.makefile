###
##. Dependencies
###

PHP_TESTING_TOOLS_DIRECTORY?=$(wildcard $(patsubst %/all.makefile,%,$(filter %/php-testing-tools/all.makefile,$(MAKEFILE_LIST))))
ifeq ($(PHP_TESTING_TOOLS_DIRECTORY),)
$(error Please provide the variable PHP_TESTING_TOOLS_DIRECTORY before including this file.)
endif

###
##. Includes
###

include $(PHP_TESTING_TOOLS_DIRECTORY)/phpunit.makefile
include $(PHP_TESTING_TOOLS_DIRECTORY)/combined.makefile
