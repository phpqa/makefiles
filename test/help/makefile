###
##. Makefiles
###

MAKEFILES_DIRECTORY:=$(abspath $(dir $(firstword $(MAKEFILE_LIST)))/../../)

###
## About
###

IMAGE_BUILD_DIRECTORY=$(MAKEFILES_DIRECTORY)/test/.cache

include $(MAKEFILES_DIRECTORY)/base.makefile
include $(MAKEFILES_DIRECTORY)/help.makefile
include $(MAKEFILES_DIRECTORY)/programs/docker.makefile
include $(MAKEFILES_DIRECTORY)/test/test.makefile

###
## Tests
###

# Run tests
tests: IMAGE_TAG=test-image:for-help
tests: | container.image.base.load $(DOCKER_DEPENDENCY)
	$(eval $(@)_RUN:=$(DOCKER) run --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" "$(IMAGE_TAG)")
	$(Q)$(call test,make help prints title ,$($(@)_RUN) sh -c 'make help','^About$$')
	$(Q)$(call test,make help prints target,$($(@)_RUN) sh -c 'make help','help')
.PHONY: tests
