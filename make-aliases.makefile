###
##. Configuration
###

MAKE_ALIASES_NAMES?=

###
##. Make aliases
###

ifneq ($(MAKE_ALIASES_NAMES),)
#. Hand-off to the MAKE_ALIASES_MAKEFILE
$(foreach name,$(MAKE_ALIASES_NAMES),$(if $(MAKE_ALIASES_MAKEFILE_$(name)),%-$(name))):
	@cd "$(dir $(MAKE_ALIASES_MAKEFILE_$(patsubst $(*)-%,%,$(@))))" && $(MAKE) -f "$(notdir $(MAKE_ALIASES_MAKEFILE_$(patsubst $(*)-%,%,$(@))))" $(*)

define make-handoff-alias
  $(1): | $(1)-$(2)
  .PHONY: $(1)
endef
#. Hand-off to the MAKE_ALIASES_MAKEFILE, but without the name suffix
$(foreach name,$(MAKE_ALIASES_NAMES),$(if $(MAKE_ALIASES_DIRECT_$(name)), \
$(foreach alias,$(MAKE_ALIASES_DIRECT_$(name)),$(eval $(call make-handoff-alias,$(alias),$(name))))))
endif
