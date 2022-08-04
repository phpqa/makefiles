###
##. Parent Makefile
###

PARENT_MAKEFILES?=$(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)/makefile ../makefile

#. Create a parent makefile to redirect commands to the current directory
$(PARENT_MAKEFILES): force-recreate-makefile
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
