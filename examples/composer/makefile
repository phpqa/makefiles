###
##. Configuration
###

include ../../base.makefile
include ../../help.makefile
include ../../docker.makefile

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP:=php

include ../../bin-php.makefile
include ../../bin-composer.makefile

include ../../php-quality-assurance-tools/all.makefile
include ../../php-testing-tools/all.makefile

# Run everything
all: vendor
	@true
.PHONY: all
