###
## Tests
###

#. ${1} is the message
#. ${2} is the command to run
#. ${3} the optional grep string to check against
#. ${4} the optional expected exit code
test=\
	printf "%s " "$(strip $(1))"; \
	output="$$(set -e; $(2) 2>&1)"; result="$$?"; \
	grep_output="$$($(if $(strip $(3)),printf "%s" "$${output}" | grep $(strip $(3)),true))"; grep_result="$$?"; \
	if test "$${result}" = "$(or $(4),0)" -a "$${grep_result}" = "0"; then \
		printf '$(STYLE_SUCCESS)$(ICON_SUCCESS)$(STYLE_RESET)\n'; \
	else \
		printf '$(STYLE_ERROR)$(ICON_ERROR)$(STYLE_RESET)\n'; \
		printf '$(STYLE_WARNING)%s$(STYLE_RESET)\n%s\n' "$(2) 2>&1" "$${output}"; \
		if test "$${result}" != "$(or $(4),0)"; then \
			exit $${result}; \
		else \
			$(if $(strip $(3)),printf '$(STYLE_WARNING)%s$(STYLE_RESET)\n%s\n' "grep $(strip $(3))" "$${grep_output}";) \
			$(if $(strip $(3)),printf "$(STYLE_WARNING)%s$(STYLE_RESET)\n%s\n" "cat --show-nonprinting --show-ends --show-tabs" "$$(printf "%s" "$${output}" | cat --show-nonprinting --show-ends --show-tabs)";) \
			exit $${grep_result}; \
		fi; \
	fi

#. Print the value of the variable before its expansion
variable.%.value:
	@printf '"%s"' '$(value $(*))'

#. Print the value of the variable after its expansion
variable.%.expanded-value:
	@printf '"%s"' '$($(*))'
