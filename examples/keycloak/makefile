###
##. Configuration
###

include ../../base.makefile
include ../../help.makefile
include ../../docker.makefile

DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK=keycloak

include ../../keycloak-on-docker-compose.makefile

# Run everything
all: compose.up keycloak.ensure-ready keycloak.export
.PHONY: all
