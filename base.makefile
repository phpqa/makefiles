###
##. Basics
###

RUN_UID?=$(shell cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
CWD?=$(shell cd "$(dir $(firstword $(MAKEFILE_LIST)))"; pwd)

###
##. Make
###

MAKE_PARALLELISM_OPTIONS = $(if $(shell $(MAKE) -v | grep "3\|4"), -j "$$(nproc 2>/dev/null || sysctl -n hw.physicalcpu 2>/dev/null || echo "1")" ,)$(if $(shell $(MAKE) -v | grep "4"), --output-sync=recurse,)

###
##. Spaces
###

SPACE:=$(shell printf " ")
ESCAPED_SPACE:=\$(SPACE)
ENCODED_SPACE:=+
COMMA:=,

###
##. Stylesheets
###

STYLE_RESET:=\033[0m
STYLE_TITLE:=\033[1;36m
STYLE_WARNING:=\033[33m
STYLE_ERROR:=\033[31m
STYLE_SUCCESS:=\033[32m
STYLE_DIM:=\033[2m
STYLE_BOLD:=\033[1m
STYLE_UNDERLINED:=\033[4m

STYLE_SUCCESS_ICON := $(STYLE_SUCCESS)\342\234\224$(STYLE_RESET)
STYLE_WARNING_ICON := $(STYLE_WARNING)\342\232\240$(STYLE_RESET)
STYLE_ERROR_ICON := $(STYLE_ERROR)\342\234\226$(STYLE_RESET)

###
##. Printf
###

# $(1) is the title, $(2) is the rest
define printer
print_$(1)=printf "$$(STYLE_$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]'))%s$$(STYLE_RESET)%s" "$$(1)" "$$(2)";
println_$(1)=printf "$$(STYLE_$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]'))%s$$(STYLE_RESET)%s\\n" "$$(1)" "$$(2)";
endef
$(foreach type,title warning error success,$(eval $(call printer,$(type))))

# $(1) is the url, $(2) is the (optional) description
print_link=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\ " "$(1)" "$(if $(2),$(2),$(1))";
println_link=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\ \\n" "$(1)" "$(if $(2),$(2),$(1))";

###
##. Environment variables lookup
###

DEFAULT_ENV_FILE?=.env
BASH_NAME_REGEX?=[_[:alpha:][:digit:]]+
BASH_VARIABLE_REGEX?=\\\$$$(BASH_NAME_REGEX)|\\\$$\{$(BASH_NAME_REGEX)\}
# $(1) is file, $(2) is variable
parse_env_string=\
	RESULT='$(strip $(2))'; \
	while printf "%s" "$${RESULT}" | grep --quiet --extended-regexp "$(BASH_VARIABLE_REGEX)"; do \
		VARIABLE="$$(printf "%s" "$${RESULT}" | sed --silent --regexp-extended "s/.*($(BASH_VARIABLE_REGEX)).*/\1/p")"; \
		VARIABLE_NAME="$$(printf "%s" "$${VARIABLE}" | sed --silent --regexp-extended "s/^\\\$$\{?($(BASH_NAME_REGEX))\}?$$/\1/p")"; \
		VARIABLE_VALUE="$$( ( $(foreach file,$(strip $(1)) $(strip $(1)).local,( grep -F "$${VARIABLE_NAME}" "$(file)" 2>/dev/null || true ) && ) true ) | sed --silent --regexp-extended "s/^$${VARIABLE_NAME}[ ]*=[ ]*(\"([^\"]+)\"|'([^']+)'|(.*))$$/\2\3\4/p" | tail -n 1)"; \
		ESCAPED_VARIABLE="$$(printf "%s" "$${VARIABLE}" | sed -e "s/[]\/$*.^[]/\\\\&/g")"; \
		ESCAPED_VARIABLE_VALUE="$$(printf "%s" "$${VARIABLE_VALUE}" | sed -e "s/[\/&]/\\\\&/g")"; \
		RESULT="$$(printf "%s" "$${RESULT}" | sed "s/$${ESCAPED_VARIABLE}/$${ESCAPED_VARIABLE_VALUE}/")"; \
	done; \
	echo "$${RESULT}";
# $(1) is file, $(2) is variable
print_env_variable=printf "%s" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))";
println_env_variable=printf "%s\\n" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))";
get_env_variable=$(shell $(call print_env_variable,$(1),$(2)))

check_variable_is_not_empty=if test -z "$${$(strip $(1))}"; then $(call println_error,Could not find the $(strip $(1)) environment variable.); exit 1; fi;

###
## About
###

.PHONY: help debug
.DEFAULT_GOAL:=help

# Show this help
help:
	@regexp=$$( \
		$(MAKE) list-make-targets-as-database \
			| awk -F ";" '/^[a-zA-Z0-9_%\/\.-]+/{ if (skipped) printf "|"; printf "^%s:", $$3; skipped=1 }' \
	); \
	if test -n "$${regexp}"; then \
		for file in $(shell $(MAKE) list-makefiles); do \
			awk -v pattern="$${regexp}" ' \
				{ if (/^## /) { printf "\n%s\n",substr($$0,4); next } } \
				{ if ($$0 ~ pattern && doc) { gsub(/:.*/,"",$$1); printf "\033[36m%-40s\033[0m %s\n", $$1, doc; } } \
				{ if (/^# /) { doc=substr($$0,3,match($$0"# TODO",/# TODO/)-3) } else { doc="No documentation" } } \
				{ if (/^#\. /) { doc="" } } \
				{ gsub(/#!/,"\xE2\x9D\x97 ",doc) } \
			' "$${file}"; \
		done; \
	fi; \
	printf "\\n"

# Print debugging information
debug:
	@$(call println_title,Run UID,)
	@printf "  %s\\n" "$(RUN_UID)"
	@$(call println_title,Current working directory,)
	@printf "  %s\\n" "$(CWD)"
	@$(call println_title,Loaded makefiles,)
	@$(MAKE) list-makefiles | awk '$$0="  "$$0'
	@$(call println_title,Used makeflags,)
	@printf "  %s\\n" "$(MAKEFLAGS)"

###
##. Debug
###

.PHONY: list-makefiles list-make-variables-as-database list-make-variables list-make-targets-as-database list-make-targets

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
			{ if (/^# Not a target:/) { included=1; next } } \
			{ if (/^([^#]+):/) { if (included==1) { match($$0,/:/); file=substr($$0,0,RSTART-1) } } } \
			{ if (/^$$|^[\t]+$$/) { if (file) { search=replace=file; gsub(" ","\\ ",replace); gsub(" "search,replace"\n",MAKEFILE_LIST) }; original=""; file=""; included=0; } } \
			\
			END { printf "%s",MAKEFILE_LIST } \
		'

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
				line="000000" substr($$0,RSTART+5,RLENGTH-5); \
				line=substr(line, 1 + length(line) - 6); \
				source="included"; \
				next \
			} } \
			{ if (/^#/) { source=substr($$0,3); next } } \
			\
			{ if (/^[A-Z0-9_-][a-zA-Z0-9_-]+ ?(=|\?=|:=)/) { printf "%s;%s;%s;%s\n",file,line,$$1,source; file=""; line=""; source="" } } \
		' \
		| sort -t ";" -k 1,1 -k 2,2 -u

#. List all make variables
list-make-variables:
	@$(MAKE) list-make-variables-as-database \
		| awk -F ";" -v STYLE_UNDERLINED="$(STYLE_UNDERLINED)" -v STYLE_RESET="$(STYLE_RESET)" ' \
			{ \
				if ($$1 != printed_file) { printf "\n" STYLE_UNDERLINED "%s" STYLE_RESET "\n",$$1; printed_file=$$1 } \
				system("make list-make-variable-" $$3) \
			} \
		'

#. List all make targets as semi-colon separated list
list-make-targets-as-database:
	@$(MAKE) --jobs=1 --always-make --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk \
			-v STYLE_TITLE="$(STYLE_TITLE)" \
			-v STYLE_WARNING="$(STYLE_WARNING)" \
			-v STYLE_DIM="$(STYLE_DIM)" \
			-v STYLE_RESET="$(STYLE_RESET)" \
			' \
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
						if (command && included==0) { \
							printf "%s;%s;%s;%s\n", \
							file, \
							line, \
							command, \
							phony ? "phony" : "" \
						}; \
						command=""; \
						phony=0; \
						included=0; \
						file=""; \
						line=""; \
					} \
				} \
				{ if (/^([^#]+):/) { match($$0,/:/); command=substr($$0,0,RSTART-1) } } \
				{ if (/^# Not a target:/) { included=1; next } } \
				{ if (/^#  Phony target/) { phony=1; next } } \
				{ if (/^#  recipe to execute/) { \
					match($$0,/from [^[:alnum:]][^\)]+[^[:alnum:]],/); \
					file=substr($$0,RSTART+6,RLENGTH-8); \
					gsub(" ","\\ ",file); \
					match($$0,/line [0-9]+/); \
					line="000000" substr($$0,RSTART+5,RLENGTH-5); \
					line=substr(line, 1 + length(line) - 6); \
					next \
				} } \
			' \
		| sort -t ";" -k 1,1 -k 2,2 -u

#. List all make targets
list-make-targets:
	@$(MAKE) list-make-targets-as-database  \
		| awk -F ";" -v STYLE_UNDERLINED="$(STYLE_UNDERLINED)" -v STYLE_TITLE="$(STYLE_TITLE)" -v STYLE_WARNING="$(STYLE_WARNING)" -v STYLE_RESET="$(STYLE_RESET)" ' \
			{ \
				{ if ($$1 != printed_file) { printf "\n" STYLE_UNDERLINED "%s" STYLE_RESET "\n",$$1; printed_file=$$1 } } \
				{ printf "%s%s\n",STYLE_TITLE $$3 STYLE_RESET,$$4=="phony"?STYLE_WARNING "*" STYLE_RESET:"" } \
			} \
		'

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
##. Force
###

.PHONY: force

#. Force
force: ; @true
