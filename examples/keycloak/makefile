###
## About
###

include ../../base.makefile
include ../../help.makefile

###
## Docker
###

DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK=keycloak
include ../../programs/docker.makefile

###
## Keycloak
###

include ../../generic-tools/keycloak-on-docker-compose.makefile

###
## Project
###

# Run everything
all: compose.up keycloak.ensure-ready keycloak.export
.PHONY: all
