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

include $(MAKEFILES_DIRECTORY)/programs/jq.makefile
include $(MAKEFILES_DIRECTORY)/programs.makefile

# Run tests with jq
tests-with-jq: IMAGE_TAG=test-image:with-jq
tests-with-jq: | container.image.base.target.with-jq.load
	$(eval $(@)_RUN:=$(DOCKER) run --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" "$(IMAGE_TAG)")
	$(Q)$(call test,JQ is /usr/bin/jq when jq is available,$($(@)_RUN) sh -c 'make variable.JQ.expanded-value','^"/usr/bin/jq"$$')
	$(Q)$(call test,JQ is usable when jq is available,$($(@)_RUN) sh -c 'make jq.assure-usable')
.PHONY: tests-with-jq

# Run tests without jq
tests-without-jq: IMAGE_TAG=test-image:without-jq
tests-without-jq: | container.image.base.target.without-jq.load
	$(eval $(@)_RUN:=$(DOCKER) run --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" "$(IMAGE_TAG)")
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/jq'
	$(Q)$(call test,JQ is an empty string when jq is not available,$($(@)_RUN) sh -c 'make variable.JQ.expanded-value','^""$$')
	$(Q)$(call test,JQ is not usable when jq is not available,$($(@)_RUN) sh -c 'make jq.assure-usable','Please provide the variable "JQ"',2)
.PHONY: tests-without-jq

# Run tests with jq
tests-with-jq-image: IMAGE_TAG=test-image:with-jq-image
tests-with-jq-image: | container.image.base.target.with-jq-image.load
	$(eval $(@)_RUN:=$(DOCKER) run --tty --workdir "$(abspath $(CWD))" --volume "$(MAKEFILES_DIRECTORY):$(MAKEFILES_DIRECTORY)" --volume "$(DOCKER_SOCKET):$(DOCKER_SOCKET)" "$(IMAGE_TAG)")
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/jq && JQ_IMAGE_VERSION=1.7 make bin/jq'
	$(Q)$(call test,JQ is bin/jq when the bin/jq file is present,$($(@)_RUN) sh -c 'make variable.JQ.expanded-value','^"bin/jq"$$')
	$(Q)$(call test,JQ is usable when the bin/jq file is present,$($(@)_RUN) sh -c 'make jq.assure-usable')
	$(Q)$(call test,JQ is the correct version when the bin/jq file is present,$($(@)_RUN) sh -c 'bin/jq --version','^jq-1.7')
	$(Q)$($(@)_RUN) sh -c 'rm -f bin/jq'
	$(Q)$(call test,JQ is bin/jq when JQ is being set to bin/jq,$($(@)_RUN) sh -c 'JQ=bin/jq JQ_IMAGE_VERSION=1.7 make variable.JQ.expanded-value','^"bin/jq"$$')
	$(Q)$(call test,JQ is usable when JQ is being set to bin/jq,$($(@)_RUN) sh -c 'JQ=bin/jq JQ_IMAGE_VERSION=1.7 make jq.assure-usable')
	$(Q)$(call test,JQ is the correct version when JQ is being set to bin/jq,$($(@)_RUN) sh -c 'bin/jq --version','^jq-1.7')
.PHONY: tests-with-jq-image

# Run tests
tests:
	@( make tests-with-jq )
	@( make tests-without-jq )
	@( make tests-with-jq-image )
.PHONY: tests
