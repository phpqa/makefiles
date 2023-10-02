###
##. Makefiles
###

MAKEFILES_DIRECTORY:=$(abspath $(dir $(firstword $(MAKEFILE_LIST)))/../)

###
## About
###

include $(MAKEFILES_DIRECTORY)/base.makefile
include $(MAKEFILES_DIRECTORY)/help.makefile

###
## Tests
###

ALL_TESTS:=$(filter-out $(MAKEFILES_DIRECTORY)/test/makefile,$(shell find $(MAKEFILES_DIRECTORY)/test/ -type f -name 'makefile'))

# Run tests from makefile
$(ALL_TESTS):%/makefile:
	$(Q)cd "$(*)" && $(MAKE) tests
.PHONY: $(ALL_TESTS)

# Run tests
tests: $(ALL_TESTS); @true
