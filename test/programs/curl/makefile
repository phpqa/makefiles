###
##. Makefiles
###

MAKEFILES_DIRECTORY:=$(abspath $(dir $(firstword $(MAKEFILE_LIST)))/../../../)

###
## Base
###

IMAGE_BUILD_DIRECTORY=$(MAKEFILES_DIRECTORY)/test/.cache

include $(MAKEFILES_DIRECTORY)/base.makefile
include $(MAKEFILES_DIRECTORY)/programs/docker.makefile
include $(MAKEFILES_DIRECTORY)/test/test.makefile

###
## Tests
###

include $(MAKEFILES_DIRECTORY)/programs/curl.makefile
include $(MAKEFILES_DIRECTORY)/programs.makefile

# Run tests with curl
tests-with-curl: IMAGE_TAG=test-image:with-curl
tests-with-curl: | container.image.base.target.with-curl.load
	$(eval $(@)_RUN:=$(DOCKER) run --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" "$(IMAGE_TAG)")
	$(Q)$(call test,CURL is /usr/bin/curl when curl is available,$($(@)_RUN) sh -c 'make variable.CURL.expanded-value','^"/usr/bin/curl"$$')
	$(Q)$(call test,CURL is usable when curl is available,$($(@)_RUN) sh -c 'make curl.assure-usable')
.PHONY: tests-with-curl

# Run tests without curl
tests-without-curl: IMAGE_TAG=test-image:without-curl
tests-without-curl: | container.image.base.target.without-curl.load
	$(eval $(@)_RUN:=$(DOCKER) run --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" "$(IMAGE_TAG)")
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/curl'
	$(Q)$(call test,CURL is an empty string when curl is not available,$($(@)_RUN) sh -c 'make variable.CURL.expanded-value','^""$$')
	$(Q)$(call test,CURL is not usable when curl is not available,$($(@)_RUN) sh -c 'make curl.assure-usable','Please provide the variable "CURL"',2)
.PHONY: tests-without-curl

# Run tests with curl
tests-with-curl-image: IMAGE_TAG=test-image:with-curl-image
tests-with-curl-image: | container.image.base.target.with-curl-image.load
	$(eval $(@)_RUN:=$(DOCKER) run --tty --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" --volume "$(DOCKER_SOCKET):$(DOCKER_SOCKET)" "$(IMAGE_TAG)")
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/curl && CURL_IMAGE_VERSION=8.3.0 make bin/curl'
	$(Q)$(call test,CURL is bin/curl when the bin/curl file is present,$($(@)_RUN) sh -c 'make variable.CURL.expanded-value','^"bin/curl"$$')
	$(Q)$(call test,CURL is usable when the bin/curl file is present,$($(@)_RUN) sh -c 'make curl.assure-usable')
	$(Q)$(call test,CURL is the correct version when the bin/curl file is present,$($(@)_RUN) sh -c 'bin/curl --version','^curl 8.3.0')
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/curl'
	$(Q)$(call test,CURL is bin/curl when CURL is being set to bin/curl,$($(@)_RUN) sh -c 'CURL=bin/curl make variable.CURL.expanded-value','^"bin/curl"$$')
	$(Q)$(call test,CURL is usable when CURL is being set to bin/curl,$($(@)_RUN) sh -c 'CURL=bin/curl make curl.assure-usable')
	$(Q)$(call test,CURL is the correct version when CURL is being set to bin/curl,$($(@)_RUN) sh -c 'bin/curl --version','^curl 8.3.0')
.PHONY: tests-with-curl-image

# Run tests
tests:
	@( make tests-with-curl )
	@( make tests-without-curl )
	@( make tests-with-curl-image )
.PHONY: tests
