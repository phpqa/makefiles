###
## About
###

include ../../base.makefile
include ../../help.makefile

###
## Dependencies
###

include ../../programs/git.makefile
include ../../programs/jq.makefile

###
## Docker & Compose
###

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP:=php

include ../../programs/docker.makefile

###
## PHP & Composer
###

include ../../programs/php.makefile
include ../../programs/composer.makefile

###
## Quality Assurance Tools
###

include ../../php/tools/composer.makefile
include ../../php/tools/composer-normalize.makefile
include ../../php/tools/franzl-studio.makefile
include ../../php/tools/friendsofphp-php-cs-fixer.makefile
include ../../php/tools/php-parallel-lint.makefile
include ../../php/tools/phpstan.makefile
include ../../php/tools/qossmic-deptrac.makefile
include ../../php/tools/rector.makefile
include ../../php/tools/squizlabs-php_codesniffer.makefile
include ../../php/tools/vimeo-psalm.makefile
include ../../php/combined/php-check.makefile
include ../../php/combined/php-fix.makefile
include ../../php/tools/phpunit.makefile
include ../../php/combined/php-test.makefile

###
## Composer Test Project
###

# Install everything
install: | compose.service.php.ensure-running
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" vendor $(PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES) $(PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES) $(PHP_TESTING_TOOLS_DEPENDENCIES)
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" composer.configure-strict composer.check-platform-reqs composer-normalize composer.validate
.PHONY: install

# Clean all directories and files
clean: | compose.service.php.ensure-stopped
	-@rm -rf bin
	-@rm -rf .composer
	-@rm -rf vendor
	-@rm -f composer.json
	-@rm -f composer.lock
.PHONY: clean
