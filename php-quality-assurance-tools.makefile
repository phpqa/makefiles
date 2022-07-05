###
##. Configuration
###

PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY?=$(wildcard $(patsubst %.makefile,%,$(filter %/php-quality-assurance-tools.makefile,$(MAKEFILE_LIST))))
ifeq ($(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY),)
$(error Please provide the variable PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY before including this file.)
endif

###
##. PHP Quality Assurance Tools
###

include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/php-parallel-lint.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/composer.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/composer-normalize.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/squizlabs-php_codesniffer.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/friendsofphp-php-cs-fixer.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/phpstan.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/vimeo-psalm.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/qossmic-deptrac.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/rector.makefile
include $(PHP_QUALITY_ASSURANCE_TOOLS_DIRECTORY)/combined.makefile
