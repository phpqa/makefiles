###
##. Parent Makefile
###

PARENT_MAKEFILE_DIRECTORY?=..
PARENT_MAKEFILES?=$(realpath $(dir $(firstword $(MAKEFILE_LIST)))/$(PARENT_MAKEFILE_DIRECTORY))/makefile $(PARENT_MAKEFILE_DIRECTORY)/makefile

#. Create a parent makefile to redirect commands to the current directory
$(filter-out $(PARENT_MAKEFILE_DIRECTORY)/makefile,$(PARENT_MAKEFILES)) $(PARENT_MAKEFILE_DIRECTORY)/makefile: force-recreate-makefile
	@printf "%s\n" "# Generated to redirect" > "$(@)"
	@printf "%s\n" ".SUFFIXES:" >> "$(@)"
	@printf "%s\n" "MAKEFLAGS+=--no-print-directory --no-builtin-rules --no-builtin-variables" >> "$(@)"
	@printf "%s\n" ".PHONY: force" >> "$(@)"
	@printf "%s\n" ".DEFAULT_GOAL:=$(.DEFAULT_GOAL)" >> "$(@)"
	@printf "%s\n" "\$$(MAKEFILE_LIST): ; @true" >> "$(@)"
	@printf "%s\n" "%: force; @cd \"$(notdir $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST))))))\" && \$$(MAKE) --file=\"$(firstword $(MAKEFILE_LIST))\" \$$(*)" >> "$(@)"
	@printf "%s\n" "force:" >> "$(@)"

#. Force the makefile to be recreated
force-recreate-makefile:
	@true
.PHONY: force-recreate-makefile
