###
##. Configuration
###

ifndef COMMAND_NAMES
$(error Please provide some command names before including $(filter %/dependencies.makefile,$(MAKEFILE_LIST)))
endif

###
##. Dependencies
###

#. Error if command % is not found
$(foreach command,$(COMMAND_NAMES),$(command).not-found):%.not-found:
	$(if $(COMMAND_VARIABLE_PREFIX_$(*)),,$(error Please provide the variable "COMMAND_VARIABLE_PREFIX_$(*)"))
	$(if $($(COMMAND_VARIABLE_PREFIX_$(*))),,$(error Please provide the variable "$(COMMAND_VARIABLE_PREFIX_$(*))"))
	$(error Please provide $(*))
.PHONY: $(foreach command,$(COMMAND_NAMES),$(command).not-found)

#. Assure that command % is usable
$(foreach command,$(COMMAND_NAMES),$(command).assure-usable):%.assure-usable:
	@$(if $(COMMAND_VARIABLE_PREFIX_$(*)),,$(error Please provide the variable "COMMAND_VARIABLE_PREFIX_$(*)"))
	@$(if $($(COMMAND_VARIABLE_PREFIX_$(*))),,$(error Please provide the variable "$(COMMAND_VARIABLE_PREFIX_$(*))"))
	@$(if $(filter bin/$(*),$($(COMMAND_VARIABLE_PREFIX_$(*)))),$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" --silent bin/$(*))
	@set +e; \
		output="$$($(or $($(COMMAND_VARIABLE_PREFIX_$(*))_USABILITY_CHECK_COMMAND),$(if $($(COMMAND_VARIABLE_PREFIX_$(*))),$($(COMMAND_VARIABLE_PREFIX_$(*))) --version 2>&1),exit 1))"; \
		exit_code="$$?"; \
		if test "$${exit_code}" != "0"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use $(*) as provided by "$(COMMAND_VARIABLE_PREFIX_$(*))=$(value $(COMMAND_VARIABLE_PREFIX_$(*)))".'; \
			printf "%s\n" "$${output}"; \
			exit $${exit_code}; \
		fi
.PHONY: $(foreach command,$(COMMAND_NAMES),$(command).assure-usable)

#. Create a bin/% file to run % from the image provided by the $(COMMAND_VARIABLE_PREFIX_%)_IMAGE_TAG variable
$(foreach command,$(COMMAND_NAMES),$(if $(value $(COMMAND_VARIABLE_PREFIX_$(command))_IMAGE_TAG),bin/$(command))):bin/%: $(MAKEFILE_LIST)
ifndef DOCKER
	$(error Please provide docker)
endif
	@$(if $(COMMAND_VARIABLE_PREFIX_$(*)),,$(error Please provide the variable "COMMAND_VARIABLE_PREFIX_$(*)"))
	@$(if $($(COMMAND_VARIABLE_PREFIX_$(*))_IMAGE_TAG),,$(error Please provide the variable "$(COMMAND_VARIABLE_PREFIX_$(*))_IMAGE_TAG"))
	@$(DOCKER) image pull "$($(COMMAND_VARIABLE_PREFIX_$(*))_IMAGE_TAG)"
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@ID="$$($(DOCKER) image inspect --format "{{.ID}}" "$($(COMMAND_VARIABLE_PREFIX_$(*))_IMAGE_TAG)")"; \
		printf "%s\\n" "#!/usr/bin/env sh" > "$(@)"; \
		printf "%s\\n" "ID=\"$${ID}\"" >> "$(@)"; \
		printf "%s\\n" "if test -z \"\$$($(DOCKER) image inspect --format \"{{.ID}}\" \"\$${ID}\" 2>/dev/null)\"; then" >> "$(@)"; \
		printf "%s\\n" "  tail -n +\$$((\$$(grep --text --line-number '^ARCHIVE:\$$' \$${0} | cut -d ':' -f 1) + 1)) \$${0} | $(DOCKER) image load --quiet" >> "$@"; \
		printf "%s\\n" "fi" >> "$(@)"; \
		printf "%s\\n" "$(DOCKER) run --rm --interactive --tty$(if $($(COMMAND_VARIABLE_PREFIX_$(*)_CONTAINER_RUN_FLAGS)), $($(COMMAND_VARIABLE_PREFIX_$(*))_CONTAINER_RUN_FLAGS)) \"\$${ID}\" \$$@" >> "$(@)"; \
		printf "%s\\n" "exit 0" >> "$(@)"; \
		printf "%s\\n" "ARCHIVE:" >> "$(@)"; \
		$(DOCKER) image save "$${ID}" >> "$(@)"
	@chmod +x "$(@)"
