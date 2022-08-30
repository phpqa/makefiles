###
##. Configuration
###

DOCKER_TOOLS_DIRECTORY?=$(wildcard $(dir $(filter %/tools-for-docker-project.makefile,$(MAKEFILE_LIST)))/docker-tools)

###
##. Requirements
###

ifeq ($(DOCKER_TOOLS_DIRECTORY),)
$(error Please provide the variable DOCKER_TOOLS_DIRECTORY before including this file.)
endif

###
##. Docker Tools
###

include $(DOCKER_TOOLS_DIRECTORY)/ctop.makefile
include $(DOCKER_TOOLS_DIRECTORY)/dive.makefile
include $(DOCKER_TOOLS_DIRECTORY)/dockly.makefile
include $(DOCKER_TOOLS_DIRECTORY)/dozzle.makefile
include $(DOCKER_TOOLS_DIRECTORY)/dry.makefile
include $(DOCKER_TOOLS_DIRECTORY)/hadolint.makefile
include $(DOCKER_TOOLS_DIRECTORY)/lazydocker.makefile
include $(DOCKER_TOOLS_DIRECTORY)/portainer.makefile
include $(DOCKER_TOOLS_DIRECTORY)/traefik.makefile
include $(DOCKER_TOOLS_DIRECTORY)/trivy.makefile
include $(DOCKER_TOOLS_DIRECTORY)/watchtower.makefile
include $(DOCKER_TOOLS_DIRECTORY)/yacht.makefile
