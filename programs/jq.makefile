###
##. Configuration
###

JQ_COMMAND?=jq
ifeq ($(JQ_COMMAND),)
$(error The variable JQ_COMMAND should never be empty)
endif

JQ_DETECTED?=$(eval JQ_DETECTED:=$$(shell command -v $(JQ_COMMAND) || which $(JQ_COMMAND) 2>/dev/null))$(JQ_DETECTED)
JQ_DEPENDENCY?=$(if $(JQ_DETECTED),jq.assure-usable,$(if $(DOCKER_DETECTED),$(DOCKER_DEPENDENCY),jq.not-found))
ifeq ($(JQ_DEPENDENCY),)
$(error The variable JQ_DEPENDENCY should never be empty)
endif

JQ_DOCKER_IMAGE?=stedolan/jq:latest
JQ?=$(if $(JQ_DETECTED),$(JQ_COMMAND),$(if $(DOCKER_DETECTED),$(DOCKER) run --rm --interactive $(JQ_DOCKER_IMAGE),$(JQ_COMMAND)))
ifeq ($(JQ),)
$(error The variable JQ should never be empty)
endif

###
##. jq
##. Lightweight and flexible command-line JSON processor
##. @see https://stedolan.github.io/jq/
###

#. Exit if JQ_COMMAND is not found
jq.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install jq."
	@exit 1
.PHONY: jq.not-found

#. Assure that JQ is usable
jq.assure-usable:
	@if test -z "$$($(JQ) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use jq as "$(value JQ)".'; \
		$(JQ) --version; \
		exit 1; \
	fi
.PHONY: jq.assure-usable
