###
##. Configuration
###

TOOLS_DIRECTORY?=$(wildcard $(dir $(filter %/tools-for-php-project.makefile,$(MAKEFILE_LIST)))/tools)
ifeq ($(TOOLS_DIRECTORY),)
$(error The variable TOOLS_DIRECTORY should never be empty)
endif

###
##. Includes
###

include $(TOOLS_DIRECTORY)/dotenv-linter.makefile
include $(TOOLS_DIRECTORY)/php-parallel-lint.makefile
include $(TOOLS_DIRECTORY)/composer.makefile
include $(TOOLS_DIRECTORY)/composer-normalize.makefile
include $(TOOLS_DIRECTORY)/squizlabs-php_codesniffer.makefile
include $(TOOLS_DIRECTORY)/friendsofphp-php-cs-fixer.makefile
include $(TOOLS_DIRECTORY)/phpstan.makefile
include $(TOOLS_DIRECTORY)/vimeo-psalm.makefile
include $(TOOLS_DIRECTORY)/qossmic-deptrac.makefile
include $(TOOLS_DIRECTORY)/rector.makefile
include $(TOOLS_DIRECTORY)/combined-php-quality-assurance-check.makefile
include $(TOOLS_DIRECTORY)/combined-php-quality-assurance-fix.makefile

include $(TOOLS_DIRECTORY)/phpunit.makefile
include $(TOOLS_DIRECTORY)/combined-php-testing.makefile
