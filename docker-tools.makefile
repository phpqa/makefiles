###
##. Configuration
###

DOCKER_TOOLS_DIRECTORY?=$(wildcard $(patsubst %.makefile,%,$(filter %/docker-tools.makefile,$(MAKEFILE_LIST))))
ifeq ($(DOCKER_TOOLS_DIRECTORY),)
$(error Please provide the variable DOCKER_TOOLS_DIRECTORY before including this file.)
endif

###
##. Docker Tools
###

include $(DOCKER_TOOLS_DIRECTORY)/ctop.makefile
include $(DOCKER_TOOLS_DIRECTORY)/lazydocker.makefile
include $(DOCKER_TOOLS_DIRECTORY)/portainer.makefile
include $(DOCKER_TOOLS_DIRECTORY)/dozzle.makefile
