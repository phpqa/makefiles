###
##. Dependencies
###

#. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
define check-env-dependency
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)")
endif
endef
$(foreach command,while grep sed echo,$(eval $(call check-env-dependency,$(command))))

###
##. Environment variables lookup
###

# TODO create a small image that can extract .env variables from files

DEFAULT_ENV_FILE?=.env
BASH_NAME_REGEX:=[_[:alpha:][:digit:]]+
BASH_VARIABLE_REGEX:=\\\$$$(BASH_NAME_REGEX)|\\\$$\{$(BASH_NAME_REGEX)\}
#. $(1) is the file, $(2) is the variable
parse_env_string=\
	TEXT='$(strip $(2))'; \
	while printf "%s" "$${TEXT}" | grep -q -E "$(BASH_VARIABLE_REGEX)"; do \
		VARIABLE="$$(printf "%s" "$${TEXT}" | sed --silent --regexp-extended "s/.*($(BASH_VARIABLE_REGEX)).*/\1/p")"; \
		VARIABLE_NAME="$$(printf "%s" "$${VARIABLE}" | sed --silent --regexp-extended "s/^\\\$$\{?($(BASH_NAME_REGEX))\}?$$/\1/p")"; \
		VARIABLE_VALUE="$$( ( $(foreach file,$(strip $(1)) $(strip $(1)).local,( grep -F "$${VARIABLE_NAME}" "$(file)" 2>/dev/null || true ) && ) true ) | sed --silent --regexp-extended "s/^$${VARIABLE_NAME}[ ]*=[ ]*(\"([^\"]+)\"|'([^']+)'|(.*))$$/\2\3\4/p" | tail -n 1)"; \
		ESCAPED_VARIABLE="$$(printf "%s" "$${VARIABLE}" | sed -e "s/[]\/$$*.^[]/\\\\&/g")"; \
		ESCAPED_VARIABLE_VALUE="$$(printf "%s" "$${VARIABLE_VALUE}" | sed -e "s/[\/&]/\\\\&/g")"; \
		TEXT="$$(printf "%s" "$${TEXT}" | sed "s/$${ESCAPED_VARIABLE}/$${ESCAPED_VARIABLE_VALUE}/")"; \
	done; \
	echo "$${TEXT}"

#. $(1) is the file, $(2) is the variable
print_env_variable=printf "%s" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))"
println_env_variable=printf "%s\\n" "$$($(call parse_env_string,$(strip $(1)),$${$(strip $(2))}))"
get_env_variable=$(shell $(call print_env_variable,$(1),$(2)))
check_variable_is_not_empty=if test -z "$${$(strip $(1))}"; then printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Could not find the $(strip $(1)) environment variable."; exit 1; fi
define define_env_variable
$(eval $(2)?=$$(eval $(2):=$$(shell $$(call print_env_variable,$(1),$(2))))$$($(2)))
endef
