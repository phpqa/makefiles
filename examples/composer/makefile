###
##. Includes
###

include ../../base.makefile
include ../../help.makefile
include ../../docker.makefile

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP:=php

include ../../bin-php.makefile
include ../../bin-composer.makefile
include ../../tools-for-php-project.makefile

###
## Composer Test Project
###

# Install everything
install: | compose.service.php.ensure-running
	@$(MAKE) vendor $(PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES) $(PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES) $(PHP_TESTING_TOOLS_DEPENDENCIES)
	@$(MAKE) composer.configure-strict composer.check-platform-reqs composer-normalize composer.validate
.PHONY: install

# Clean all directories and files
clean: | compose.service.php.ensure-stopped
	-@rm -rf bin
	-@rm -rf .composer
	-@rm -rf vendor
	-@rm -f composer.json
	-@rm -f composer.lock
.PHONY: clean
