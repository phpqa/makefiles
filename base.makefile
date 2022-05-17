###
##. Configuration
###

RUN_UID?=$(shell cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
CWD?=$(shell cd "$(dir $(firstword $(MAKEFILE_LIST)))"; pwd)

###
##. Make
###

ifneq ($(firstword $(shell $(MAKE) --version)),GNU)
$(error Please use GNU Make)
endif
MAKE_PARALLELISM_OPTIONS = $(if $(shell $(MAKE) -v | grep "3\|4"), -j "$$(nproc 2>/dev/null || sysctl -n hw.physicalcpu 2>/dev/null || echo "1")" ,)$(if $(shell $(MAKE) -v | grep "4"), --output-sync=recurse,)

###
##. Characters
###

empty:=
space:=$(empty) $(empty)
escaped_space:=\$(space)
encoded_space:=+
comma:=,

###
##. Conversions
###

uppercase?=$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]')

###
##. Stylesheets
###

STYLE_RESET?=\033[0m

STYLE_TITLE?=\033[1;36m
STYLE_SUCCESS?=\033[32m
STYLE_WARNING?=\033[33m
STYLE_ERROR?=\033[31m
STYLE_DIM?=\033[2m
STYLE_BOLD?=\033[1m
STYLE_UNDERLINE?=\033[4m

ICON_SUCCESS?=\342\234\224 # \u2713
ICON_WARNING?=\342\232\240 # \u26A0
ICON_ERROR?=\342\234\225 # \u2715

###
##. Printf
###

#. $(1) is the style, $(2) is the message
print_in_style?=printf "$(subst $(space),,$(foreach style,$(call uppercase,$(1)),$(STYLE_$(style))))%s$(STYLE_RESET)%s" "$(2)"
println_in_style?=printf "$(subst $(space),,$(foreach style,$(call uppercase,$(1)),$(STYLE_$(style))))%s$(STYLE_RESET)%s\n" "$(2)"
#. $(1) is the url, $(2) is the (optional) description
print_link?=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\\\" "$(1)" "$(if $(2),$(2),$(1))"
println_link?=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\\\\n" "$(1)" "$(if $(2),$(2),$(1))"

###
##. Environment variables lookup
###

DEFAULT_ENV_FILE?=.env
BASH_NAME_REGEX?=[_[:alpha:][:digit:]]+
BASH_VARIABLE_REGEX?=\\\$$$(BASH_NAME_REGEX)|\\\$$\{$(BASH_NAME_REGEX)\}
#. $(1) is the file, $(2) is the variable
parse_env_string=\
	RESULT='$(strip $(2))'; \
	while printf "%s" "$${RESULT}" | grep --quiet --extended-regexp "$(BASH_VARIABLE_REGEX)"; do \
		VARIABLE="$$(printf "%s" "$${RESULT}" | sed --silent --regexp-extended "s/.*($(BASH_VARIABLE_REGEX)).*/\1/p")"; \
		VARIABLE_NAME="$$(printf "%s" "$${VARIABLE}" | sed --silent --regexp-extended "s/^\\\$$\{?($(BASH_NAME_REGEX))\}?$$/\1/p")"; \
		VARIABLE_VALUE="$$( ( $(foreach file,$(strip $(1)) $(strip $(1)).local,( grep -F "$${VARIABLE_NAME}" "$(file)" 2>/dev/null || true ) && ) true ) | sed --silent --regexp-extended "s/^$${VARIABLE_NAME}[ ]*=[ ]*(\"([^\"]+)\"|'([^']+)'|(.*))$$/\2\3\4/p" | tail -n 1)"; \
		ESCAPED_VARIABLE="$$(printf "%s" "$${VARIABLE}" | sed -e "s/[]\/$$*.^[]/\\\\&/g")"; \
		ESCAPED_VARIABLE_VALUE="$$(printf "%s" "$${VARIABLE_VALUE}" | sed -e "s/[\/&]/\\\\&/g")"; \
		RESULT="$$(printf "%s" "$${RESULT}" | sed "s/$${ESCAPED_VARIABLE}/$${ESCAPED_VARIABLE_VALUE}/")"; \
	done; \
	echo "$${RESULT}"
#. $(1) is the file, $(2) is the variable
print_env_variable=printf "%s" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))"
println_env_variable=printf "%s\\n" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))"
get_env_variable=$(shell $(call print_env_variable,$(1),$(2)))
check_variable_is_not_empty=if test -z "$${$(strip $(1))}"; then $(call println_in_style,error,Could not find the $(strip $(1)) environment variable.); exit 1; fi

###
## About
###

.DEFAULT_GOAL?=help
HELP_SKIP_TARGETS?=
HELP_FIRST_COLUMN_WIDTH?=26

# Show this help
help:
	@\
	show_pattern="$$($(MAKE) list-make-targets-as-database | awk -F ";" '/^[a-zA-Z0-9_%\/\.-]+/{ if (skipped) printf "|"; printf "^%s:", $$3; skipped=1 }')"; \
	skip_pattern="$(subst $(space),|,$(foreach target,$(HELP_SKIP_TARGETS),^$(target):))"; \
	if test -z "$${show_pattern}"; then show_pattern="empty"; fi; \
	if test -z "$${skip_pattern}"; then skip_pattern="empty"; fi; \
	awk -v title_length="$(HELP_FIRST_COLUMN_WIDTH)" -v show_pattern="$${show_pattern}" -v skip_pattern="$${skip_pattern}" ' \
		{ if (/^## /) { if (title_block != "true") { title=$$0; title_block="true" }; next } else { title_block="false" } } \
		{ if (/^$$/) { skip="false"; doc=""; next } } \
		{ if (/^#\. / && doc == "") { skip="true"; next } } \
		{ if (/^# / && doc == "") { skip="false"; indent=""; doc=substr($$0,3); next } } \
		{ if (/^#[^\.\s]+ / && doc == "") { skip="false"; indent=substr($$1,2)" "; doc=substr($$0,3+length(indent)-1); next } } \
		{ if (/^# @see / && doc) { link=substr($$0,8) } } \
		{ if ($$0 ~ show_pattern && $$0 !~ skip_pattern) { \
			if (skip == "true") { skip="false"; doc=""; next } \
			if (title != "") { if (title != last_title) { printf "\n%s\n",substr(title,4) }; last_title=title }; \
			gsub(/:.*/,"",$$1); \
			printf "$(STYLE_DIM)%s$(STYLE_RESET)$(STYLE_TITLE)%-*s$(STYLE_RESET)", indent, title_length - length(indent), $$1; \
			if (doc == "") { doc="$(STYLE_DIM)No documentation$(STYLE_RESET)" }; \
			if (doc ~ /# TODO/) { doc=substr(doc,1,match(doc,/# TODO/)-1) }; \
			if (doc ~ /#!/) { warning="$(ICON_WARNING)" substr(doc,match(doc,/#!/)+2); doc=substr(doc,1,match(doc,/#!/)-1) } ; \
			if (link) { printf "\033]8;;%s\033\\%s\033]8;;\033\\", link, doc } else { printf "%s", doc }; \
			if (warning) { printf "$(STYLE_WARNING)%s$(STYLE_RESET)",warning; }; \
			printf "\n"; \
			link=""; \
			indent=""; \
			doc=""; \
			warning=""; \
		} }; \
	' $(shell $(MAKE) list-makefiles)
.PHONY: help

# Print debugging information
debug:
	@$(call println_in_style,title,Run UID)
	@printf "  %s\\n" "$(RUN_UID)"
	@$(call println_in_style,title,Current working directory)
	@printf "  %s\\n" "$(CWD)"
	@$(call println_in_style,title,Loaded makefiles)
	@$(MAKE) list-makefiles | awk '$$0="  "$$0'
	@$(call println_in_style,title,Used makeflags)
	@printf "  %s\\n" "$(MAKEFLAGS)"
.PHONY: debug

###
##. Debug
###

#. List all included makefiles
list-makefiles:
	@$(MAKE) --jobs=1 --always-make --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk -v MAKEFILE_LIST="$(MAKEFILE_LIST)" ' \
			{ if (/^# Variables/) { skip_segment=1 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=0 } } \
			{ if (/^# Files/) { skip_segment=0 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^\.PHONY|^\.SUFFIXES|^\.DEFAULT|^\.PRECIOUS/) { next } } \
			{ if (/^[\t]/) { next } } \
			\
			{ if (/^# Not a target:/) { include="yes"; next } } \
			{ if (/^([^#]+):/) { if (include=="yes") { match($$0,/:/); file=substr($$0,0,RSTART-1) } } } \
			{ if (/^$$|^[\t]+$$/) { if (file) { search=replace=file; gsub(" ","\\ ",replace); gsub(" "search,replace"\n",MAKEFILE_LIST) }; original=""; file=""; include="no"; } } \
			\
			END { printf "%s",MAKEFILE_LIST } \
		'
.PHONY: list-makefiles

#. List the value for a make variable
list-make-variable-%:
	@printf "$(STYLE_TITLE)%s$(STYLE_RESET)=%s%s\\n" \
		'$(*)' \
		'$($(*))' \
		"$$(if test '$(value $(*))' != '$($(*))'; then printf " $(STYLE_DIM)%s$(STYLE_RESET)\\n" '$(value $(*))'; fi)"

#. List all make variables as semi-colon separated list
list-make-variables-as-database:
	@$(MAKE) --jobs=1 --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk ' \
			{ if (/^# Variables/) { skip_segment=0 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=1 } } \
			{ if (/^# Files/) { skip_segment=1 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^# makefile \(from/) { \
				match($$0,/makefile \(from [^\)]+, line /); \
				file=substr($$0,RSTART+16,RLENGTH-24); \
				gsub(" ","\\ ",file); \
				match($$0,/line [0-9]+/); \
				line=substr($$0,RSTART+5,RLENGTH-5); \
				source="included"; \
				next \
			} } \
			{ if (/^#/) { \
				file=""; line=""; source=substr($$0,3); \
				next \
			} } \
			\
			{ if (/^[A-Z0-9_-][a-zA-Z0-9_-]+ ?(=|\?=|:=)/ && file && line) { \
				if ($$1 != "MAKEFILE_LIST") { \
					printf "%s;%s;%s;%s\n",file,substr("000000" line, 1 + length(line)),$$1,source; \
				} \
				file=""; line=""; source=""; \
			} } \
		' \
		| sort -t ";" -k 1,1 -k 2,2 -u
.PHONY: list-make-variables-as-database

#. List all make variables
list-make-variables:
	@$(MAKE) list-make-variables-as-database \
		| awk -F ";" -v STYLE_UNDERLINED="$(STYLE_UNDERLINED)" -v STYLE_RESET="$(STYLE_RESET)" ' \
			{ \
				if ($$1 != printed_file) { printf "\n" STYLE_UNDERLINED "%s" STYLE_RESET "\n",$$1; printed_file=$$1 } \
				system("make list-make-variable-" $$3) \
			} \
		'
.PHONY: list-make-variables

#. List all make targets as semi-colon separated list
list-make-targets-as-database:
	@$(MAKE) --jobs=1 --always-make --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk ' \
			{ if (/^# Variables/) { skip_segment=1 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=0 } } \
			{ if (/^# Files/) { skip_segment=0 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^\.PHONY|^\.SUFFIXES|^\.DEFAULT|^\.PRECIOUS/) { next } } \
			{ if (/^[\t]/) { next } } \
			\
			{ \
				if (/^$$|^[\t]+$$/) { \
					if (command && include=="yes") { \
						printf "%s;%s;%s;%s\n", \
						file ? file : "data-base", \
						line ? substr("000000" line, 1 + length(line)) : substr("000000" NR, 1 + length(NR)), \
						command, \
						is_phony=="yes" ? "phony" : "" \
					}; \
					command=""; \
					include="yes"; \
					is_phony="no"; \
					file=""; \
					line=""; \
				} \
			} \
			{ if (/^([^#]+):/) { match($$0,/:/); command=substr($$0,0,RSTART-1) } } \
			{ if (/^# Not a target:/) { include="no"; next } } \
			{ if (/^#  Phony target/) { is_phony="yes"; next } } \
			{ if (/^#  recipe to execute/) { \
				match($$0,/from [^[:alnum:]][^\)]+[^[:alnum:]],/); \
				file=substr($$0,RSTART+6,RLENGTH-8); \
				gsub(" ","\\ ",file); \
				match($$0,/line [0-9]+/); \
				line=substr($$0,RSTART+5,RLENGTH-5); \
				next \
			} } \
		' \
		| sort -t ";" -k 1,1 -k 2,2 -u
.PHONY: list-make-targets-as-database

#. List all make targets
list-make-targets:
	@$(MAKE) list-make-targets-as-database  \
		| awk -F ";" -v STYLE_UNDERLINED="$(STYLE_UNDERLINED)" -v STYLE_TITLE="$(STYLE_TITLE)" -v STYLE_WARNING="$(STYLE_WARNING)" -v STYLE_RESET="$(STYLE_RESET)" ' \
			{ \
				{ if ($$1 != printed_file) { printf "\n" STYLE_UNDERLINED "%s" STYLE_RESET "\n",$$1; printed_file=$$1 } } \
				{ printf "%s%s\n",STYLE_TITLE $$3 STYLE_RESET,$$4=="phony"?STYLE_WARNING "*" STYLE_RESET:"" } \
			} \
		'
.PHONY: list-make-targets

###
##. Redirect
###

# Create a makefile in the parent directory to redirect commands
$(realpath $(CWD)/..)/makefile ../makefile: force
	@printf "%s\n" "# Generated to redirect" > "$(@)"
	@printf "%s\n" ".SUFFIXES:" >> "$(@)"
	@printf "%s\n" "MAKEFLAGS+=--no-print-directory --no-builtin-rules --no-builtin-variables" >> "$(@)"
	@printf "%s\n" ".PHONY: force" >> "$(@)"
	@printf "%s\n" ".DEFAULT_GOAL:=$(.DEFAULT_GOAL)" >> "$(@)"
	@printf "%s\n" "\$$(MAKEFILE_LIST): ; @true" >> "$(@)"
	@printf "%s\n" "%: force; @cd "$(notdir $(CWD))" && \$$(MAKE) \$$(*)" >> "$(@)"
	@printf "%s\n" "force:" >> "$(@)"

###
##. Helpers
###

#. Force the command to run
force: ; @true
.PHONY: force

#. Run the command without printing "is up to date" messages
silent-% %.silent:%; @true
