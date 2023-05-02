###
##. Configuration
###

YACHT_PROJECTS_ROOT_DIR=$(shell cd ../../examples && pwd)

###
##. Base
###

include ../../base.makefile

###
## About
###

include ../../help.makefile

###
## Docker
###

DOCKER_COMPOSE_DIRECTORY=.
include ../../programs/docker.makefile

###
## Docker Tools
###

include ../../programs/curl.makefile
include ../../programs/jq.makefile
include ../../docker-tools/ctop.makefile
include ../../docker-tools/dive.makefile
include ../../docker-tools/dockly.makefile
include ../../docker-tools/dozzle.makefile
include ../../docker-tools/dry.makefile
include ../../docker-tools/hadolint.makefile
include ../../docker-tools/lazydocker.makefile
include ../../docker-tools/portainer.makefile
include ../../docker-tools/traefik.makefile
include ../../docker-tools/trivy.makefile
include ../../docker-tools/watchtower.makefile
include ../../docker-tools/yacht.makefile

###
## Docker Project
###

# Start services, but log some sidecar services until they successfully exit
start: DOCKER_COMPOSE_FLAGS+=--file start-and-log.compose.yaml
start: DOCKER_COMPOSE_SERVICES_TO_LOG_DURING_UP_UNTIL_SUCCESSFUL_EXIT=first second
start: compose.up
	@echo "First and second service exited successfully, do your thing now..."
