###
##. Configuration
###

include ../../builtins.makefile
include ../../base.makefile
include ../../docker.makefile

DOCKER_COMPOSE_SERVICE_NAME_FOR_PHP:=php

include ../../bin-php.makefile
include ../../bin-composer.makefile

# Run everything
all: vendor
	@true
.PHONY: all
