###
##. Configuration
###

PHP_QUALITY_ASSURANCE_DIRECTORY?=$(wildcard $(patsubst %.makefile,%,$(filter %/php-quality-assurance-tools.makefile,$(MAKEFILE_LIST))))
ifeq ($(PHP_QUALITY_ASSURANCE_DIRECTORY),)
$(error Please provide the variable PHP_QUALITY_ASSURANCE_DIRECTORY before including this file.)
endif

###
## Quality Assurance Tools
###

include $(PHP_QUALITY_ASSURANCE_DIRECTORY)/composer-validate.makefile
include $(PHP_QUALITY_ASSURANCE_DIRECTORY)/rector.makefile
include $(PHP_QUALITY_ASSURANCE_DIRECTORY)/phpstan.makefile
include $(PHP_QUALITY_ASSURANCE_DIRECTORY)/phpunit.makefile
